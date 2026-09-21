# プライバシー関連の下書き

ステータス：**下書き（オーナー確認前）**。法務判断を含むため、公開前に必ずオーナーが内容を確認する。
関連：[ANALYTICS_DESIGN.md](ANALYTICS_DESIGN.md) §8（リリース前チェックリスト）

前提（実装の実態）：

- 利用ログ（Firebase Analytics）とクラッシュ情報（Firebase Crashlytics）を収集する
- イベントに識別子は載せない（利用者・図書・家庭・組・検索語は記録しない。所要時間・件数・列挙値のみ）
- 広告ID（IDFA）は収集しない（`FirebaseAnalyticsCore`＋広告パーソナライズ無効）。ATTダイアログは出さない
- 利用者名・貸出記録は端末内（SwiftData）にのみ保存し、外部へ送信しない
- 図書情報の取得時のみ、ISBN・書名を外部の書誌検索サービスへ送る（要：公開前に現行の取得先を確認）

---

## 1. プライバシーポリシー（本文案）

> ### えほん台帳 プライバシーポリシー
>
> **1. 端末内に保存する情報**
> 利用者（園児・保護者）の名前、絵本、貸出・返却の記録は、お使いのiPad内にのみ保存されます。
> 開発者や第三者のサーバーへ送信されることはありません。
>
> **2. 開発者が収集する情報**
> アプリの改善のため、次の情報を匿名で収集します。
>
> - 操作の所要時間、検索結果の件数、操作の種類（貸出・返却・取り消し等）
> - アプリが異常終了した際のクラッシュ情報（端末の機種・OSバージョン・異常終了時の処理の記録）
>
> 利用者の名前、絵本の題名、検索した文字列など、個人や特定の絵本を識別できる情報は収集しません。
> 広告用の識別子は使用せず、収集した情報を広告やトラッキングに利用することもありません。
>
> **3. 情報の取り扱い**
> 収集した情報は、Google LLCが提供するFirebase（Analytics・Crashlytics）を通じて保存・集計され、
> アプリの品質向上のためにのみ使用します。第三者へ販売・提供しません。
>
> **4. 絵本情報の取得**
> 絵本の登録時、ISBNまたは書名を外部の書誌検索サービスへ送信して書誌情報を取得します。
> 利用者の情報は送信されません。
>
> **5. お問い合わせ**
> （連絡先を記載）
>
> 制定日：（公開日を記載）

公開先はオーナーが決める（GitHub Pages等）。App Store Connectにはそのpolicy URLを登録する。

---

## 2. App Storeのプライバシー表示（Nutrition Label）

App Store Connect →「Appのプライバシー」での申告案。

| データの種類 | 収集 | ユーザーに紐づく | トラッキングに使用 | 利用目的 |
|---|---|---|---|---|
| 利用状況データ ＞ 製品の操作 | する | **いいえ** | **いいえ** | アナリティクス |
| 診断 ＞ クラッシュデータ | する | **いいえ** | **いいえ** | アプリの機能（クラッシュ対応）／アナリティクス |
| 診断 ＞ パフォーマンスデータ | する | **いいえ** | **いいえ** | アプリの機能／アナリティクス |
| 識別子（ユーザID・デバイスID） | しない | ― | ― | ― |
| 連絡先情報・ユーザコンテンツ・検索履歴 | しない | ― | ― | ― |

注意：

- 「デバイスID」を「収集しない」と申告するには、Crashlytics/AnalyticsがIDFAを使わないことが前提。
  Firebaseは端末単位のインストールIDを内部で持つため、**申告前にFirebase公式の
  「Apple privacy details」の案内と突き合わせて最終確認する**（未確認）
- 「トラッキング」の質問は「いいえ」（他社アプリ・サイトをまたぐ追跡をしていないため）

---

## 3. PrivacyInfo.xcprivacy（アプリ側マニフェスト）

現状、アプリ側にPrivacyInfo.xcprivacyは**存在しない**（Firebase SDKは自前のものを同梱）。
アプリ本体のターゲットに追加する案：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeProductInteraction</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAnalytics</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeCrashData</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

- `UserDefaults`は貸出設定の保存（`UserDefaultsLoanSettingsRepository`）で使用しているため、
  必須理由API（CA92.1：アプリ自身の設定の読み書き）を申告する
- 他の必須理由API（ファイルタイムスタンプ等）の使用有無は、追加時にXcodeの
  「Privacy Report」（Archive → Generate Privacy Report）で最終確認する
- Nutrition Label（§2）と内容を一致させる

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
> **送らないもの**：お子さま・保護者のお名前、絵本の題名、検索した言葉、どのご家庭が何を借りたか。
> 広告のための情報も使いません。
