# プライバシー関連の下書き

ステータス：**下書き（オーナー確認前）**。法務判断を含むため、公開前に必ずオーナーが内容を確認する。
関連：[ANALYTICS_DESIGN.md](ANALYTICS_DESIGN.md) §8（リリース前チェックリスト）

前提（実装の実態）：

- 利用ログ（Firebase Analytics）とクラッシュ情報（Firebase Crashlytics）を収集する
- イベントに識別子は載せない（利用者・図書・家庭・組・検索語は記録しない。所要時間・件数・列挙値のみ）
- 広告ID（IDFA）は収集しない（`FirebaseAnalyticsCore`＋広告パーソナライズ無効）。ATTダイアログは出さない
- 利用者名・貸出記録は端末内（SwiftData）にのみ保存し、外部へ送信しない
- 図書情報の取得時のみ、ISBN・書名・著者名を楽天ブックスAPI（楽天グループ）へ送り、表紙画像を取得する（#224・#237で`main`も楽天ブックスAPIに切り替わった）
- Firebase Analyticsは匿名のアプリインスタンスID（広告IDではない）を自動で付与する

---

## 1. プライバシーポリシー（本文案）

本文は公開用の [privacy-policy.md](privacy-policy.md) に分けた。このファイルは内部メモ（確認事項・申告案）なので、
App Store Connectに登録するURLは privacy-policy のものだけにする。内容を変えるときは privacy-policy.md を直す。

公開先は GitHub Pages に決定（2026-10-01）。App Store Connectには、公開された
`.../PictureBookLendingApp/privacy-policy` のURLを登録する。

---

## 2. App Storeのプライバシー表示（Nutrition Label）

App Store Connect →「Appのプライバシー」での申告案。

| データの種類 | 収集 | ユーザーに紐づく | トラッキングに使用 | 利用目的 |
|---|---|---|---|---|
| 利用状況データ ＞ 製品の操作 | する | **いいえ** | **いいえ** | アナリティクス |
| 診断 ＞ クラッシュデータ | する | **いいえ** | **いいえ** | アプリの機能（クラッシュ対応） |
| 診断 ＞ その他の診断データ（Crashlyticsが同梱マニフェストで宣言） | する | **いいえ** | **いいえ** | アプリの機能（クラッシュ対応） |
| 利用状況データ ＞ その他の利用状況データ（起動・画面表示などの自動計測） | する | **いいえ** | **いいえ** | アナリティクス |
| 識別子 ＞ デバイスID（匿名のアプリインスタンスID） | **する** | **いいえ** | **いいえ** | アナリティクス |
| 識別子 ＞ ユーザID | しない | ― | ― | ― |
| 連絡先情報・ユーザコンテンツ・検索履歴 | しない | ― | ― | ― |

注意：

- **「デバイスID」は収集ありで申告する**。Google公式（Google Analytics for Firebaseのプライバシーラベル案内）で、
  アプリインスタンスIDが自動で割り当てられるためIDFAを使わなくても該当するとされている。
  広告ID（AdSupport）はリンクしていないので、追加の識別子申告は不要
- クラッシュレポートのパンくず（Analyticsと併用時の直前操作ログ）は、操作の種類のみで識別子を含まない
- Googleは「ラベルの正確さは各アプリの責任」と明記している。申告前にApp Store ConnectのUIの選択肢と最終突き合わせをする
- 「トラッキング」の質問は「いいえ」（他社アプリ・サイトをまたぐ追跡をしていないため）

---

## 3. PrivacyInfo.xcprivacy（アプリ側マニフェスト）

実装済み：[`PictureBookLendingAdminApp/PictureBookLendingAdmin/PrivacyInfo.xcprivacy`](../PictureBookLendingAdminApp/PictureBookLendingAdmin/PrivacyInfo.xcprivacy)
（アプリ本体ターゲットのファイルシステム同期グループに置いてあり、`.app` 直下にバンドルされる）。
Firebase SDK・Kingfisher等は自前のマニフェストを同梱している。

内容（§2と一致させている）：

- トラッキングなし（`NSPrivacyTracking`=false、`NSPrivacyTrackingDomains`は空）
- 収集データ種別：デバイスID・その他の利用状況データ・製品の操作（目的はアナリティクス）、
  クラッシュデータ・その他の診断データ（目的はアプリの機能）。いずれもユーザーに紐づけず、トラッキングに使わない
- 必須理由API：`UserDefaults`のみ（`CA92.1`：アプリ自身の設定の読み書き）。
  貸出設定（`UserDefaultsLoanSettingsRepository`）と表示倍率（`BorrowListContainerView`の`@AppStorage`）で
  使用。App Group共有は使っていない（ウィジェットは`UserDefaults`を使わない）ためウィジェット側のマニフェストは不要
- ファイルのタイムスタンプ・起動時刻・ディスク容量・キーボード情報のAPIは自前コードで使っていないため申告しない
  （コード上の使用有無は`UserDefaults`/`creationDate`/`modificationDate`/`systemUptime`等のgrepで確認済み）
- 他の必須理由APIを追加で使う場合は、本ファイルに追記し、Xcodeの
  「Privacy Report」（Archive → Generate Privacy Report）で最終確認する
- Nutrition Label（§2）と内容を一致させる
- Crashlytics・Installations・GoogleDataTransportの同梱マニフェストが「その他の診断データ」を宣言しているため、
  アプリ側と§2にも含めた（Nutrition Labelは、SDKが集めるものも含めて申告する）

---

## 4. 導入園向けの説明文

> ### 「えほん台帳」で集める情報について
>
> えほん台帳は、園児・保護者のお名前や貸出の記録を**iPadの中だけ**に保存します。外部に送られることはありません。
>
> アプリをよりよくするため、次のことだけを**匿名で**開発者に送ることがあります（iPadがWi-Fiにつながったとき）。
>
> - 「貸出に何秒かかったか」「検索で何件見つかったか」といった、操作の回数や時間
> - アプリが止まってしまったときの、機種名などの技術的な記録
>
> ※ 絵本の登録時には、ISBNや書名を楽天ブックスに送って書誌情報を取得します（園児・保護者の情報は含みません）。
>
> **送らないもの**：お子さま・保護者のお名前、絵本の題名、検索した言葉、どのご家庭が何を借りたか。
> 広告のための情報も使いません。
