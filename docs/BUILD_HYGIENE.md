# ビルド警告の整理と再発防止

## 今回の基準

Cloud 368（main `4a46e907df520ca3ed23f424d4a0e31cfc27695e`）のログを起点に整理した。
警告の大半は自作コードとテストのswift-format指摘で、Firebaseのソース警告ではなかった。
Cloudの画面件数、XCResult件数、ログの重複除去件数は一致しないため、比較時は同じ取得方法・
SDK・構成・アーキテクチャを使う。警告件数だけでクラッシュやビルド失敗と判断しない。

## 通常の開発

プロジェクトルートで次を実行する。

```sh
# 新規Swiftファイルも検査対象にするため、先にgit addする。
python3 scripts/swift_style.py --fix
python3 scripts/swift_style.py
python3 scripts/check_build_configuration.py
git diff --check
```

- `--fix`だけがソースを書き換える。ビルド中の自動整形は廃止した。
- 対象はGit追跡済みのアプリ配下のSwiftファイル。`.build`、外部パッケージ、秘密設定は探索しない。
- `.swift-format`で空行へのインデントを無効にし、lintとGitの末尾空白検査を両立する。
- Cloudの`ci_post_clone.sh`は秘密設定を生成する前に、read-onlyのstrict lintと番号設定検査を行う。
  違反を無視して後で自動修正する運用には戻さない。
- App/Widgetの`CURRENT_PROJECT_VERSION`はプロジェクトのDebug/Release共通値から継承する。
  個別ターゲットの上書きは設定検査で拒否する。配布時のコマンドライン上書きを使う場合も
  全ターゲットへ同じ値を渡し、最終Archive/IPA内のInfo.plistで一致を確認する。

## 実質的な警告

- Analyticsの型を参照する画面は定義元Infrastructureを明示importする。
- バックアップの値型と構成要素はコンパイラが検証する`Sendable`を使う。
- カメラdelegateはAVFoundationとDispatchQueueの境界であるため、限定的に
  `@unchecked Sendable`を使う。キャプチャ状態は専用queueだけ、UI参照とコールバックは
  MainActorだけに置く。将来プロパティを追加する際は必ずこの分離をレビューし、queueの
  外から状態へ直接アクセスしない。内部入口のqueue事前条件と既存の中断・停止テストを維持する。
- 年齢区分はenumの汎用デバッグ表示ではなく`displayText`を表示する。
- SDKに既にあるSendable適合を重複追加しない。Xcode 26.4/27.1 SDKのMigrationStage適合を確認した。

## 残る警告と次の対応

1. `AVCaptureConnection.videoOrientation` / `isVideoOrientationSupported`の非推奨警告は
   今回維持する。画面の向きの取得は`effectiveGeometry.interfaceOrientation`へ移行済み。
   映像回転は`videoRotationAngle`またはRotationCoordinatorを使う変更を別途検証する。
   前面カメラのプレビューと認識用ピクセルの一致、縦・上下反転・左右横、端末回転中、再試行後を
   実機で確認してから置き換える。固定角への機械置換や警告の全体抑制はしない。
2. AppIntentsを使っていないターゲットのmetadata extraction skippedは低優先。
   メッセージを消すためだけにフレームワークを追加しない。
3. Cloud 368の配布停止は上記の警告とは別件。`listTeams.action` HTTP 502 / Session Proxy Provider
   認証エラーで書き出しが止まり、テスト先のiPadも既定runtimeに未対応だった。
   Xcode Cloudのサービス状態と対応runtimeを確認してから、オーナーが必要なworkflow変更を判断する。
   コード修正で認証502を直せるとは扱わず、無制限の再実行もしない。
4. Firebase dSYM不足は368の取得ログでは検出しなかった。Crashlyticsのupload-symbols検証成功は
   確認したが、バックグラウンド転送の到着までは保証しない。次の成功した配布でArchive/dSYMの
   UUID一致、Firebase側のシンボル化、App Store側の処理結果をそれぞれ確認する。

## SDK更新・リリース前

- Xcode更新は整形ルール・Swift診断・シミュレータ対応の変化を確認する独立変更として扱う。
  SDKを固定した比較で新警告を分類してから更新し、formatterの差分は機能変更と区別してレビューする。
- lint・番号検査に加え、全体build-for-testing、関連テスト、Releaseの署名なしbuildで確認する。
  実機や実SDK通信が未確認なら、その範囲をPRに残す。
- 警告を一律に無効化しない。並行処理・型の可視性・番号不一致は修正し、残す警告には理由と
  次の確認手順を持たせる。Cloud画面の「0」だけを目標にしない。
