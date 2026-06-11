# PictureBookLendingApp

## 概要

**PictureBookLendingApp** は、保育園・幼稚園向けに *絵本の貸出・返却業務を iPad だけで完結* させる貸出管理システムです。Web サーバやクラウドを利用しない完全オフライン運用を前提とします。

**画面構成**: `docs/SCREEN_DESIGN.md` を参照

**特徴**

* **ユーザ想定**：保護書・教員
* **オフライン完結** : インターネット接続不要
* **無料配布想定** : 維持費ゼロで導入可能
* **5000 冊 / 200 ユーザ規模** を想定したローカル性能設計
* SwiftUIを使った MV ／Container–Presentation 分離による中〜大規模アプリ向けアーキテクチャ
* **Liquid Glass (iOS 26)** : 最新 HIG 準拠の透明感あるデザイン
* **デザインガイドライン** : Apple Human Interface Guidelines (HIG) 全般に準拠
* **主な機能** : 貸出／返却／絵本登録／園児登録／返却期限管理
* **非機能要件** : 最大 500 冊・200 ユーザで 1 秒以内レスポンス、ローカル暗号化ストレージ、iPad 最適化 UI
 
**仕様**

* 本を借りられる冊数は事前に決まっている
* 返却期限が設定されている

---

## プロジェクト構成

```
PictureBookLendingAdminApp
├─ PictureBookLendingAdmin          (App層 : アプリケーション層)
├─ PictureBookLendingModel          (Model層 : Swift Package)
├─ PictureBookLendingDomain         (Domain層 : Swift Package)
├─ PictureBookLendingInfrastructure (Infrastructure層 : Swift Package)
└─ PictureBookLendingUI             (UI層 : Swift Package)
```

### 前提条件

* Xcode (最新バージョン)
* macOS (最新バージョン)
* **iOS 26 以上**

### 開発コマンド

**重要**: コマンド実行時は適切なディレクトリにいることを確認してください

```bash
# プロジェクトルートディレクトリから実行（推奨）
# Xcodeプロジェクト経由でプロジェクト全体ビルド
xcodebuild -scheme PictureBookLendingAdmin build -project PictureBookLendingAdminApp/PictureBookLendingAdmin.xcodeproj

# 全テスト実行
xcodebuild -scheme PictureBookLendingAdmin test -project PictureBookLendingAdminApp/PictureBookLendingAdmin.xcodeproj

# 特定モジュールのみビルド（プロジェクトルートから）
(cd PictureBookLendingAdminApp/PictureBookLendingDomain && swift build)
(cd PictureBookLendingAdminApp/PictureBookLendingModel && swift build)
(cd PictureBookLendingAdminApp/PictureBookLendingInfrastructure && swift build)
(cd PictureBookLendingAdminApp/PictureBookLendingUI && swift build)

# 特定モジュールのテスト実行（プロジェクトルートから）
(cd PictureBookLendingAdminApp/PictureBookLendingModel && swift test)
(cd PictureBookLendingAdminApp/PictureBookLendingDomain && swift test)
(cd PictureBookLendingAdminApp/PictureBookLendingInfrastructure && swift test)

# コードフォーマット（swift-format）- プロジェクトルートから
(cd PictureBookLendingAdminApp && swift format --configuration .swift-format --in-place --recursive **/*.swift)

# 特定モジュールのみフォーマットとリント（ルートディレクトリから）
# 修正範囲が限定的な場合は、該当モジュールのみ処理することを推奨

# メインアプリのフォーマット・リント（プロジェクトルートから）
(cd PictureBookLendingAdminApp && swift format lint --configuration .swift-format --recursive PictureBookLendingAdmin/)
(cd PictureBookLendingAdminApp && swift format --configuration .swift-format --in-place --recursive PictureBookLendingAdmin/)

# 各モジュールのフォーマット・リント（プロジェクトルートから）
(cd PictureBookLendingAdminApp && swift format lint --configuration .swift-format --recursive ${MODULE_NAME}/Sources/)
(cd PictureBookLendingAdminApp && swift format --configuration .swift-format --in-place --recursive ${MODULE_NAME}/Sources/)

# 具体例：PictureBookLendingModelモジュールの場合（プロジェクトルートから）
(cd PictureBookLendingAdminApp && swift format lint --configuration .swift-format --recursive PictureBookLendingModel/Sources/)
(cd PictureBookLendingAdminApp && swift format --configuration .swift-format --in-place --recursive PictureBookLendingModel/Sources/)

# サブシェル使用により、元のディレクトリ位置を維持
# 各コマンドは ( ) 内で実行され、完了後に元の位置に戻る
```

### 技術スタック

* **SwiftUI / Observation** : UI & リアクティブバインディング
* **SwiftData** : 永続化 (Core Data ラッパー)
* **Swift Package Manager** : 依存管理・モジュール分割

---

## 作業手順

0. Modelを実装する際はt-wadaの推奨する進め方に従いTDDで開発を進める

1. **コード修正後は必ずビルドとテストを実行する**

   * プロジェクトルートから: `cd PictureBookLendingAdminApp && xcodebuild -scheme PictureBookLendingAdmin build` で **プロジェクト全体** がビルドできることを確認
   * プロジェクトルートから: `cd PictureBookLendingAdminApp && xcodebuild -scheme PictureBookLendingAdmin test` で **全テスト** が成功することを確認

2. **影響範囲が限定的な場合**

   * 修正前に対象モジュールのフォーマット・リントを実行（プロジェクトルートから）:
     * `cd PictureBookLendingAdminApp && swift format lint --configuration .swift-format --recursive <ModuleName>/Sources/`
     * `cd PictureBookLendingAdminApp && swift format --configuration .swift-format --in-place --recursive <ModuleName>/Sources/`
   * モジュールディレクトリから: `cd PictureBookLendingAdminApp/<ModuleName> && swift build` で **そのモジュールのみビルド**
   * モジュールディレクトリから: `cd PictureBookLendingAdminApp/<ModuleName> && swift test` で **関連テストのみ実行**
3. **swift-format 警告** がビルド時に発生した場合は可能な限り対応し、難しい場合は相談する。

---

## PR・マージ方針

判定基準：**「このPRの合否は目と指でしか判定できないか？」**

* **実機確認してからマージ**：UX・アニメーション・ハプティクス・レイアウト等、
  使用感が本質の変更。PR作成後はマージせず、ユーザーが実機で確認してOKを
  出してからマージする。調整（表示時間・文言等）はマージ前にPR上で行う
* **即マージしてよい**：ドキュメント・リファクタリング・テストで正しさを
  判定できる修正
* このリポジトリはGitHub設定で auto-merge が無効のため、グローバル設定の
  `gh pr merge --auto` は使わず `gh pr merge <PR番号> --squash --delete-branch`
  で直接マージする

---

## 🏗 アーキテクチャ概要（SwiftUI 共通指針）

### 採用パターン

* **Container / Presentation** パターン
* **5 モジュール構成** : App / Model / Domain / Infrastructure / UI
* **Observation + SwiftData** によるリアクティブ & 永続化

### モジュール依存関係

```
App層 ──┬──▶ Model層
        ├──▶ Domain層  
        ├──▶ Infrastructure層
        └──▶ UI層
        
Model層 ────▶ Domain層
Infrastructure層 ──▶ Domain層
UI層 ─────────▶ Domain層
※上記以外の依存は禁⽌
```

| モジュール                            | 主な責務                          |
| -------------------------------- | ----------------------------- |
| **App層** (PictureBookLendingAdmin)    | アプリエントリーポイント・ContainerView   |
| **Model層** (PictureBookLendingModel)  | ビジネスロジック・状態管理・Observable   |
| **Domain層** (PictureBookLendingDomain) | ドメインエンティティ・Repository プロトコル (純 Swift) |
| **Infrastructure層** (PictureBookLendingInfrastructure) | Repository 実装・永続化・外部 API   |
| **UI層** (PictureBookLendingUI)        | ピュア UI コンポーネント・Preview 用モック |

### サンプル実装

```swift
public struct Book: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public let title: String
    public let author: String
    public let targetAge: Int
    public let publishedAt: Date
    /// 年齢の適合判定
    public func isSuitable(for age: Int) -> Bool { age >= targetAge }
}
```

```swift
@MainActor
public final class BooksModel: ObservableObject {
    @Published var books: [Book] = []
    private let repository: BookRepository
    public init(repository: BookRepository) { self.repository = repository }
    /// データ取得
    func load() async throws {
        books = try await repository.fetchAll()
    }
}
```

```swift
struct BookListContainerView: View {
    @StateObject private var booksModel = BooksModel(repository: .live)
    @State private var alertState = AlertState()
    @State private var searchText = ""

    var body: some View {
        BookListView(
            books: filteredBooks,
            searchText: $searchText,
            onSelect: handleSelect(_:)
        )
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .task { await load() }
    }

    private var filteredBooks: [Book] {
        searchText.isEmpty ? booksModel.books : booksModel.books.filter { $0.title.contains(searchText) }
    }

    private func handleSelect(_ book: Book) {
        // 画面固有ロジック
    }

    private func load() async {
        do { try await booksModel.load() }
        catch { alertState = .error("読込に失敗しました") }
    }
}
```

---

## 状態管理の分類

* **個別プロパティ** : `searchText`, `selectedIDs` など画面限定の一時状態
* **共通 State 型** : `AlertState`, `NavigationState`, `LoadingState` など複数画面で再利用
  * **重要**: State型はApp層（ContainerViewと同じモジュール）に定義する
* **Model** : アプリ横断で共有するビジネスロジック状態 (`BooksModel`, `UsersModel`)

---

## 🎯 責任分離（Separation of Concerns）

| 責任                   | Model | State | Container | Presentation |
| -------------------- | ----- | ----- | --------- | ------------ |
| データ永続化・API 通信        | ✅     | ❌     | ❌         | ❌            |
| 直接 API 呼び出し          | ✅     | ❌     | ❌         | ❌            |
| アプリ全体状態              | ✅     | ❌     | ❌         | ❌            |
| 複雑なビジネスロジック          | ✅     | ❌     | ❌         | ❌            |
| 画面固有状態               | ❌     | ✅     | ✅         | ❌            |
| 共通 State 調整          | ❌     | ✅     | ✅         | ❌            |
| Presentation へのデータ供給 | ❌     | ❌     | ✅         | ❌            |
| NavigationStack       | ❌     | ❌     | ✅         | ❌            |
| alert/sheet/popover   | ❌     | ❌     | ✅         | ❌            |
| onAppear/task/refreshable | ❌     | ❌     | ✅         | ❌            |
| UI 詳細実装              | ❌     | ❌     | ❌         | ✅            |
| 純粋 UI 表示             | ❌     | ❌     | ❌         | ✅            |

---

## 🛠️ コードガイドライン

### SwiftUI 実装指針

* クロージャをプロパティに持つ View は **Equatable** 準拠を検討
* `let` プロパティのライフサイクルが異なる場合は **View 分割** を検討
* `body` 内で重い計算／副作用を持つ **computed property** を避ける
* Model では `Task` の使用を避け、**async 関数** 使用し、単体テストしやすい形にする
* Model は Repository **Protocol への依存** に留める

### コードスタイルガイドライン

* Foundation の型を使わない場合は `import Foundation` を書かない
* **Swift 6.0** の機能を使用する (`swift-tools-version: 6.0`)
* UI は **SwiftUI** を使用
* 色指定は `foregroundStyle` を優先 (`foregroundColor` は極力避ける)
* `overlay` を優先し、`ZStack` は必要時のみ
* 間隔調整は `spacing` を優先し、`padding` は必要最小限に
* 命名は **Swift API Design Guidelines**／標準ライブラリに従う
* **AnyViewは使用禁止**: 型消去が必要な場合はジェネリクスまたは@ViewBuilderを使用する
* **マジックナンバーを使用しない**: 数値リテラルが意味を持つ場合はenum、定数、computed propertyで定義する
  * **画面固有の状態**: ContainerView内にprivate enumを定義
  * **ドメイン共通の定数**: Domainモジュールに定義  
  * **アプリ設定値**: App層に定数として定義

### Boolean変数の命名規則

* **sheet/alert/popover表示状態**: `isXXPresented` (例: `isAddSheetPresented`, `isDeleteAlertPresented`)
* **一般的な状態**: `isXX` (例: `isLoading`, `isSelected`, `isEmpty`)
* **能力**: `canXX` (例: `canEdit`, `canDelete`, `canSave`)
* **断言として読める**: Swift API Design Guidelinesに従い「〜である」と自然に読める形

### SwiftUIプロパティの順序

SwiftUI Viewのプロパティは以下の順序で定義する：

1. **@Environment** - システム・環境レベルの依存関係
2. **@EnvironmentObject** - アプリレベルの共有状態  
3. **@StateObject** - View所有の参照型
4. **@ObservedObject** - 外部所有の参照型
5. **@State** - View所有の値型
6. **@Binding** - 外部所有の値型
7. **通常プロパティ** - `let`/`var`（ラッパーなし）
8. **computed properties** - 計算プロパティ
9. **body** - Viewの本体
10. **メソッド** - 関数定義

**例**:
```swift
struct ExampleView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = ExampleViewModel()
    @State private var isSheetPresented = false
    @Binding var selectedItem: Item
    
    let title: String
    
    private var filteredItems: [Item] { ... }
    
    var body: some View { ... }
    
    private func handleAction() { ... }
}
```

### プロパティ命名規則

* **@State変数**: `private var` でキャメルケース
* **@Environment変数**: `private var` でキャメルケース  
* **通常プロパティ**: 用途に応じて`let`/`var`、キャメルケース
* **computed properties**: `private var` でキャメルケース
* **メソッド**: `private func` で動詞から始まる（`handle*`, `perform*`, `update*`等）
* 値型 (`struct` / `enum`) エンティティは **Sendable + Codable** 準拠
* Associated value を持たない `enum` は **Hashable** 準拠
* インスタンス状態に依存しないメソッドは **static** で定義し、呼び出しには `Self.` を付ける
* 単一式の場合は `return` を省略し、`
  if`／`switch` 式を活用

### ドメイン用語の統一

* **必須**: `docs/TERMS.md` の用語集に準拠した命名を行う
* **日本語表記**: UI表示、コメント、ドキュメントは用語集の「日本語（UI用）」列を使用
* **英語表記**: コード内の変数名、クラス名、プロパティ名は用語集の「英語（コード・設計用）」列を使用
* **避ける用語**: 用語集の「避ける用語」列に記載された表現は使用禁止
* **新規用語**: 新しいドメイン概念が必要な場合は、まず `docs/TERMS.md` を更新してから実装する
* **一貫性チェック**: 実装前に既存コードとの用語統一を確認する

**例**:
```swift
// ✅ 正しい用語使用
struct Book { ... }           // 英語: Book
let user = User(...)          // 英語: User  
Text("絵本を追加")            // 日本語: 絵本
Text("利用者一覧")            // 日本語: 利用者

// ❌ 避けるべき用語
struct Booklet { ... }        // 避ける: Booklet
let child = Child(...)        // 避ける: Child
Text("書籍を追加")            // 避ける: 書籍
Text("園児一覧")              // 避ける: 園児
```

```swift
// switch 式の例
enum Bar { case a, b, c }
func foo(bar: Bar) -> Int {
    switch bar {
    case .a: 2
    case .b: 3
    case .c: 5
    }
}
```

* 名前空間を意識し、**nested type** を活用
* 関連関数では **引数の順序を一貫** させる
* Unit Test には **XCTest** を使用し、テストクラスで整理

---

## 📊 プレゼンテーションロジック

* 表示用データ整形・入力値バリデーションなどは **`App層/Presentation`** 配下に配置
* フォーマットが必要な表示はDomain オブジェクトごとに `+Formatter.swift` を用意する。

---

## 🧪 単体テスト方針

1. **Domain / Model / State / Formatter** は必ず単体テストを作成する。
