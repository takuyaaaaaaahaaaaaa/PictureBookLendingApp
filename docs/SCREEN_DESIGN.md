# 画面設計書

## 🏠 タブバー（貸出・返却・履歴・設定）

### 📚 貸出（絵本から）
```
└ 絵本一覧画面 (BookListContainerView)
  ├ 検索バー・フィルタボタン（統一UI）
  ├ ソート・絞り込みオプション
  ├ 各行に「貸出」ボタン → 貸出フローへ [Sheet遷移]
  └ 絵本詳細画面 (BookDetailContainerView) [Navigation遷移]
    └ 「貸出」ボタン → 貸出フローへ [Sheet遷移]

貸出フロー（共通）:
└ 貸出フロー画面 (LoanFlowContainerView) [Sheet遷移]
  └ 組選択画面 (ClassGroupSelectionContainerView) [Navigation遷移]
    └ 利用者選択画面 (UserSelectionContainerView) [Navigation遷移]
      └ 貸出確認画面 (LoanConfirmationContainerView) [Navigation遷移]
        └ 貸出完了 [Dialog表示]
```

### 👦 返却・履歴（利用者から）
```
└ 組選択画面 (ClassGroupSelectionContainerView)
  └ 利用者一覧画面 (UserListContainerView)
    ├ 検索バー・フィルタボタン（統一UI）
    ├ ソート・絞り込みオプション
    └ 利用者詳細画面 (UserDetailContainerView) [Navigation遷移]
      ├ 貸出中絵本一覧（返却ボタンあり）
      ├ 貸出履歴一覧
      └ 「この利用者に新規貸出」ボタン → 絵本選択画面 → 貸出確認・完了
```

### ⚙️ 設定（管理者用）
```
└ 設定画面 (SettingsContainerView)
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
    ├ 絵本一覧／新規登録／編集／削除
    ├ 絵本詳細 (BookDetailContainerView) [Navigation遷移]
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
  - 貸出フローの段階的遷移

### Sheet遷移 (sheet)
**用途**: 登録・編集・フローなど、モーダルな操作
- **特徴**: キャンセル・保存ボタンが必要
- **適用例**:
  - 新規登録フォーム
  - 編集フォーム
  - 貸出フロー全体

### Dialog表示 (alert)
**用途**: 確認・アラート・完了通知など、簡単な情報表示
- **特徴**: OK・キャンセルボタンでの確認
- **適用例**:
  - 削除確認
  - エラーメッセージ
  - 処理完了通知

## 共通UI要素

### 検索・フィルタUI
- 検索バー（統一デザイン）
- フィルタボタン
- ソート・絞り込みオプション