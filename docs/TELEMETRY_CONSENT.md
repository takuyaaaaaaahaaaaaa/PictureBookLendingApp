# 任意の利用状況・診断送信

## 動作と同意

- 主な利用者は保護者・教員。子ども向けカテゴリとして配信する予定ではない（オーナー確認）。
- 新規・既存インストールとも同意がなければ未選択。解析と診断は独立で、オフのまま貸出・返却できる。
- 新規のセットアップでは組・利用者・図書の登録後、貸出画面に戻る直前に任意の送信選択を表示する。初回案内で「あとで設定する」を選んだ場合も、案内を閉じた直後に送信選択を表示する。選択前にアプリを終了した場合は次回起動時に再表示する。「同意して貸出へ」は解析と診断を両方オン、「送信せずに貸出へ」は両方オフにする。選択前は送信しない。
- 初期選択は両項目を一度に保存し、保存成功後に送信を有効化する。保存失敗は画面を閉じずalertで再試行を求める。既存ユーザーの未選択状態は貸出・返却を妨げず、設定のプライバシー画面から選択できる。片方でも選択済みなら既存設定を維持する。
- 管理者は「設定 → プライバシーとデータ送信」で項目ごとに許可・撤回できる。
- Analyticsは同意中だけイベントを転送する。撤回はgateを先に閉じ、SDK停止、同期ファイル保存、端末データ/アプリインスタンスIDのリセットを行う。サーバー情報の削除ではない。
- 診断は**初回許可後、毎回の操作なしに起動時に自動送信**する。保存済み全件（同意前・オフ期間を含む）も送信対象になることを許可前に説明する。クラッシュは端末に記録され、通常は次回起動で送信される。
- 診断オフは次回起動から反映。送信開始済み情報は取り消せない。未送信情報が端末に残り、再許可で送信対象になることも説明する。
- SDKの自動収集は常にfalse。アプリが保存された診断同意を確認し、公式`sendUnsentReports`を起動ごとに一度だけ要求する。許可直後も同じ経路を使い、同一起動のon/off/onで要求を重複させない。
- `checkForUnsentReports=false`はactive以外のキューまで空という保証ではない。独自のキュー来歴・空確認フラグは持たない。送信対象は明示許可された保存済み全件。
- 同意はバージョン付きJSONをatomic write後にFileHandle.synchronizeで保存する。成功後だけ画面状態を更新。失敗時はAnalyticsを止め、永続設定の確定状態を確認できないことと再試行をalert表示する。atomic置換後のsynchronize失敗もあるため、以前のファイルが残っているとは断定しない。診断の開始済み要求は取り消せたと扱わない。
- アプリの分析イベント/診断ログへ園児・保護者名、図書名、検索語、業務レコードIDを追加しない。設定変更自体も分析しない。

## 指標の制限

自動操作はアプリ側で行うが、SDK上は`sendUnsentReports`経路である。この経路はsession情報を送らないため、**クラッシュ原因の調査に使えても、crash-free users/sessionsの割合を正しく算出できない場合がある**。リリースの品質判定にその母数指標だけを使わない。
根拠: [Crashlyticsの収集設定と指標品質](https://firebase.google.com/docs/crashlytics/crash-free-metrics#impact_of_data_collection_settings_on_metrics_quality)。

## Analytics起動前停止の根拠

Info.plistのfalseだけでは、SDKが保存したtrueを上書きできない。`FirebaseTelemetryRuntime.configure`は毎回`Analytics.setAnalyticsCollectionEnabled(false)`を**FirebaseApp.configureより先に**呼ぶ。構成後に、アプリの現在同意を適用する。これにより診断だけを許可した場合や同意ファイルが破損した場合にも、古いAnalytics許可を引き継がない。

固定SDK: firebase-ios-sdk 12.18.0 (`346daa9f46316aa372b35b317e18224acc2e9063`)。
独立レビューでiOS arm64バイナリを静的解析し、停止と実初期化が同一serial queueにこの順で投入されることを確認した。

| バイナリ | SHA-256 |
| --- | --- |
| FirebaseAnalytics | aa32cc9dd2f32eefbf7667a773d7f820665c17658595d14b178c9d12045a6452 |
| GoogleAppMeasurement | b075917c5bad651690c19e9217b8c3fdaee4c4b987ccad3a4e409cd3bd6c3f34 |

再現: 各xcframeworkのios-arm64 frameworkバイナリへ`shasum -a 256`と`xcrun llvm-objdump --macho --disassemble`を実行する。
- `+[FIRAnalytics setAnalyticsCollectionEnabled:]` (0x198–0x1a4) → `+[APMAnalytics setAnalyticsEnabled:persistSetting:]` (0x1134–0x1184)。初期化済み条件なしで0x1178から共通queueへ停止処理を投入。
- 停止blockはfalseを状態2にし、0x11d4で`setMeasurementEnabledState:`を呼ぶ。同setterの0x488でdispatch_syncにより設定処理を完了。
- `+[APMAnalytics startWithAppID:origin:options:]`のblockは0x838で同じqueueへ実初期化を投入し、次のblock内0x984で`initializeSharedInstanceWithAppID:...`を実行。
- 共通`dispatchAsyncOnSerialQueue:`は0xedc–0xf2c。0xf14でdispatch_async。

アドレスはアーカイブ内オブジェクト単位。公開API文書にはconfigure前呼出の明文保証がないため、これは**固定バイナリに限定した根拠**。SDK更新時は再確認し、実SDKの起動通信検証も必要。

## 公開前の残作業

- Spyで同意・撤回・再起動・重複要求・保存失敗・破損を検証。実SDKネットワーク検証は別。GoogleService-Info.plistなしのローカルビルドで、実送信確認済みとはしない。
- テスト用Firebase環境で新規/既存更新/解析だけ/診断だけ/拒否/撤回/再起動/同意ファイル破損とSDK永続値不整合の通信を確認する。実クラッシュ→再起動→Console到着、シンボル化も確認する。
- 現行mainにCrashlyticsの自動true設定を追加する呼出はない。今後別ビルドがSDKの永続trueを残す場合は更新経路を再検証する（configure後falseだけで初期送信を防げるとはしない）。
- Firebase/Google Analyticsの実保持設定（2/14か月、リセット設定、集計例外）をオーナーが確認。Consoleは今回変更しない。
- Crashlyticsは90日保持後に稼働系/バックアップから削除を開始する。90日目の削除完了とは表示しない。
- 公開ポリシーURLは2026-10-02にPages builtとGET200を確認。本文差分はまだ未公開。最終レビュー後に公開本文・App Store Connect申告を揃える。

## 公式資料

- [Analyticsの収集設定](https://firebase.google.com/docs/analytics/ios/configure-data-collection)
- [Analytics API](https://firebase.google.com/docs/reference/swift/firebaseanalytics/api/reference/Classes/Analytics)
- [Crashlyticsの任意送信](https://firebase.google.com/docs/crashlytics/ios/customize-crash-reports)
- [固定SDKのキュー制御](https://github.com/firebase/firebase-ios-sdk/blob/346daa9f46316aa372b35b317e18224acc2e9063/Crashlytics/Crashlytics/Controllers/FIRCLSReportManager.m)
- [Firebaseの保持・削除](https://firebase.google.com/support/privacy)
- [Google Analyticsの保持設定](https://support.google.com/analytics/answer/7667196)
