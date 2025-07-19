# 画面設計書

## 🏠 タブバー（貸出・返却）

**変更点**: 設定タブを削除し、ツールバーからのアクセスに変更

### 📚 貸出（絵本から）
```
└ 絵本一覧画面 (BookListContainerView)
  ├ ツールバー：「⚙️設定」ボタン → 設定画面 [fullScreenCover遷移]
  ├ 検索バー・フィルタボタン（統一UI）
  ├ ソート・絞り込みオプション
  ├ 各行にLoanActionContainerButton（状態応答型）
  │ ├ 貸出可能時：「貸出」ボタン → 貸出画面へ [Sheet遷移]
  │ └ 貸出中時：「返却」ボタン → 返却確認 [Dialog表示]
  └ 絵本詳細画面 (BookDetailContainerView) [Navigation遷移]
    ├ ツールバー：「⚙️設定」ボタン → 設定画面 [fullScreenCover遷移]
    ├ 貸出状況：BookStatusView（リアルタイム更新）
    └ LoanActionContainerButton（状態応答型）
      ├ 貸出可能時：「貸出」ボタン → 貸出画面へ [Sheet遷移]
      └ 貸出中時：「返却」ボタン → 返却確認 [Dialog表示]

貸出画面（共通）:
└ 貸出画面 (LoanFormContainerView) [Sheet遷移]
  ├ 絵本情報（タイトル・管理ID）- 固定表示
  ├ 組選択 - Picker（必須選択）
  ├ 利用者選択 - Picker（組選択後にフィルタリング表示）
  ├ 返却期限 - 自動計算表示（非編集）
  ├ 貸出上限チェック（自動）
  │ ├ 上限以内：貸出ボタン活性
  │ └ 上限超過：貸出ボタン非活性 + エラーメッセージ表示
  └ 貸出実行 → 完了Dialog表示
```

### 🔄 返却（組別グルーピング表示）
```
└ 返却管理画面 (ReturnContainerView)
  ├ ツールバー：「⚙️設定」ボタン → 設定画面 [fullScreenCover遷移]
  ├ フィルタ機能
  │ ├ 組別フィルタ（全組・年少・年中・年長など）- Picker
  │ └ 利用者名絞り込み - Picker（全利用者・特定利用者選択）
  ├ 貸出中一覧（組別グルーピング表示）
  │ └ 組A
  │   ├ 利用者Aさん：絵本A 返却期限 [返却ボタン]
  │   └ 利用者Bさん：絵本B 返却期限 [返却ボタン]
  │ └ 組B
  │   └ 利用者Cさん：絵本C 返却期限 [返却ボタン]
  └ 各返却ボタン → 返却確認 [Dialog表示]

※ 設計方針：
- デフォルト：貸出中のみ表示（利用者1人1冊前提）
- 将来拡張対応：履歴機能、延滞フィルタ、タイトル別フィルタに対応可能な柔軟設計
```

## ⚙️ 設定画面（fullScreenCover遷移）

**変更点**: タブバーから除外し、各画面のツールバーからアクセス

```
└ 設定画面 (SettingsContainerView) [fullScreenCover遷移]
  ├ ヘッダー：「✕閉じる」ボタン（元画面に戻る）
  ├ 貸出設定
  │ └ 貸出可能冊数の設定（デフォルト3冊）
  ├ 組管理 (ClassGroupListContainerView) [Navigation遷移]
  │ ├ 組一覧／新規登録／編集／削除
  │ ├ 組追加フォーム (ClassGroupFormContainerView) [Sheet遷移]
  │ └ 組編集フォーム (ClassGroupFormContainerView) [Sheet遷移]
  ├ 利用者管理 (UserListContainerView) [Navigation遷移]
  │ ├ 利用者一覧／新規登録／編集／削除
  │ ├ 利用者詳細 (UserDetailContainerView) [Navigation遷移]
  │ ├ 利用者追加フォーム (UserFormContainerView) [Sheet遷移]
  │ └ 利用者編集フォーム (UserFormContainerView) [Sheet遷移]
  └ 絵本管理 (BookListContainerView) [Navigation遷移]
    ├ 絵本一覧／新規登録／編集／削除（BookStatusView付き）
    ├ 絵本詳細 (BookDetailContainerView) [Navigation遷移]
    │ ├ 貸出状況：BookStatusView（リアルタイム更新）
    │ └ LoanActionContainerButton（状態応答型）
    ├ 絵本追加フォーム (BookFormContainerView) [Sheet遷移]
    └ 絵本編集フォーム (BookFormContainerView) [Sheet遷移]
```

## ナビゲーションパターン

### Navigation遷移 (navigationDestination)
**用途**: 詳細表示、一覧表示、メイン機能の画面遷移
- **特徴**: 戻るボタンが自動で表示される
- **適用例**:
  - 一覧 → 詳細
  - メニュー → サブメニュー
  - 設定画面内での階層遷移

### Sheet遷移 (sheet)
**用途**: 登録・編集・フローなど、モーダルな操作
- **特徴**: キャンセル・保存ボタンが必要
- **適用例**:
  - 新規登録フォーム
  - 編集フォーム
  - 貸出フロー（LoanFormContainerView）

### fullScreenCover遷移 (fullScreenCover)
**用途**: 全画面モーダル表示、独立した機能セット
- **特徴**: 全画面表示、「✕閉じる」ボタンで復帰
- **適用例**:
  - 設定画面（SettingsContainerView）
  - ツールバーからのアクセス

### Dialog表示 (alert)
**用途**: 確認・アラート・完了通知など、簡単な情報表示
- **特徴**: OK・キャンセルボタンでの確認
- **適用例**:
  - 削除確認
  - エラーメッセージ
  - 処理完了通知
  - 返却確認

## 共通UI要素

### 検索・フィルタUI
- 検索バー（統一デザイン）
- フィルタボタン
- ソート・絞り込みオプション

### 状態表示・アクションコンポーネント
- **BookStatusView**: 絵本の貸出状況を視覚的に表示
  - 貸出可能：緑のドット + "利用可"
  - 貸出中：オレンジのドット + "貸出中"
  - カプセル型のバッジデザイン

- **LoanActionContainerButton**: 状態応答型アクションボタン
  - 貸出可能時：「貸出」ボタン（青色）
  - 貸出中時：「返却」ボタン（赤色）
  - 状態変更時のリアルタイム更新対応

### エラーハンドリング
- **LocalizedError対応**: 全Modelエラーで日本語エラーメッセージ
- **貸出上限チェック**: 自動的に貸出可能冊数を確認
- **ユーザーフレンドリーなエラー表示**: AlertStateでの統一的なエラー表示

### 多言語対応
- **日付表示**: SwiftUIネイティブAPIによる自動ローカライゼーション
- **エラーメッセージ**: 日本語での分かりやすいメッセージ表示