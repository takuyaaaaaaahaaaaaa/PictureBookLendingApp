# 絵本登録機能（タイトル・著者検索→Google Books API連携）実装プラン

## 📋 概要
保育園の既存絵本にはISBNバーコードがないため、タイトルと著者名での検索を使った絵本登録機能を実装します。

## 🎯 機能要件
- タイトル・著者名の手動入力
- Google Books APIでの書籍検索
- 複数候補からの選択
- 検索結果のスコアリング・並び替え
- 見つからない場合の手動登録
- 日本語絵本への最適化

## 🏗️ アーキテクチャ設計

### 1. Domainレイヤーの拡張
- `Book.swift`: publisher、publishedDate、description、thumbnailURL等を追加
- `BookMetadataGatewayProtocol`: 外部APIからの書誌情報取得を抽象化（既存）
- `StringNormalizer`: 文字列正規化ユーティリティ
- `BookSearchScorer`: 検索結果スコアリング

### 2. Infrastructureレイヤーの実装
- `GoogleBooksAPIClient`: タイトル・著者検索対応（既存を拡張）
- `BookMetadataGateway`: `BookMetadataGatewayProtocol`の実装（既存）
- `JapaneseStringNormalizer`: 日本語特化の正規化実装

### 3. Modelレイヤーの拡張  
- `BookModel`: タイトル・著者検索、候補選択メソッドを追加
- `BookCandidate`: 検索候補を表現するDTO

### 4. UIレイヤーの実装
- `BookSearchView`: タイトル・著者入力フォーム
- `BookCandidateListView`: 検索結果一覧・選択
- `BookManualRegistrationView`: 手動登録フォーム
- `BookRegistrationView`: 統合登録画面

### 5. Appレイヤーの実装
- `BookRegistrationContainerView`: 状態管理とビジネスロジック

## 📱 実装段階

### Phase 1: Domain層の基盤整備
1. `StringNormalizer`プロトコルとテスト実装
   - 全角・半角統一
   - 記号正規化（中黒、ハイフン、長音等）
   - スペース正規化
   - ひらがな・カタカナ変換
2. `BookSearchScorer`実装
   - タイトル類似度計算
   - 著者名類似度計算
   - 言語・出版社による加点
3. `BookCandidate`モデル定義

### Phase 2: Google Books API検索拡張
1. タイトル・著者での検索クエリ生成
   - 厳密検索（完全一致）
   - 緩和検索（部分一致）
   - 段階的検索戦略
2. 検索結果のマッピング
3. エラーハンドリング

### Phase 3: Infrastructure完成
1. `JapaneseStringNormalizer`実装
   - 旧字体・異体字対応
   - 役割語（作・絵・文等）の処理
2. API統合テスト

### Phase 4: Model層実装
1. `BookModel`の検索機能拡張
2. 検索結果のスコアリング・ソート
3. 候補選択・確定フロー

### Phase 5: UI実装
1. `BookSearchView`
   - タイトル入力フィールド
   - 著者入力フィールド
   - デバウンス処理
2. `BookCandidateListView`
   - スコア順表示
   - 差分ハイライト
   - 詳細情報表示
3. `BookManualRegistrationView`
   - 最小限の必須項目
   - カメラでカバー撮影

### Phase 6: 統合・最適化
1. `BookRegistrationContainerView`実装
2. 既存の`BookFormContainerView`との統合
3. パフォーマンス最適化
4. エラーハンドリング改善

### Phase 7: 拡張機能（オプション）
1. ローカル辞書機能
2. OCRによる入力補助
3. 検索履歴・学習機能

## 🔧 技術仕様

### 文字列正規化仕様
```swift
protocol StringNormalizer {
    func normalize(_ input: String) -> String
}

// 正規化の例：
// "ぐり　と　ぐら" → "ぐりとぐら"
// "なかがわ・りえこ" → "なかがわ りえこ"
// "宮沢　賢治" → "宮沢賢治"
```

### Google Books API クエリ戦略
1. **厳密検索**
   ```
   intitle:"ぐりとぐら" inauthor:"なかがわ りえこ"
   ```

2. **準厳密検索**
   ```
   intitle:"ぐりとぐら" inauthor:"なかがわ"
   ```

3. **緩和検索**
   ```
   intitle:ぐり intitle:ぐら inauthor:なかがわ
   ```

### スコアリング仕様
- タイトル類似度: 70%
- 著者類似度: 30%
- 言語ボーナス: +5%（日本語）
- 出版社存在ボーナス: +2%

### データモデル
```swift
struct BookCandidate {
    let title: String
    let authors: [String]
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let thumbnailURL: URL?
    let language: String?
    let score: Double
}
```

## ⚠️ 注意点
- 日本語の表記ゆれへの対応が必須
- 著者名の姓名順、役割表記の多様性
- API使用量の管理（デバウンス、キャッシュ）
- 完全オフライン時の手動登録フロー確保
- 検索で見つからない絵本への対応

## 🧪 テスト戦略
- 正規化ロジックの網羅的テスト
- スコアリングアルゴリズムのテスト
- 様々な日本語絵本での実API検証
- 表記ゆれパターンのテストケース
- オフライン時の動作確認

## 📊 成功指標
- 既存絵本の80%以上が検索でヒット
- 検索結果の上位3件以内に正解が含まれる率90%以上
- 平均登録時間: 30秒以内
- 手動登録の必要性: 20%以下

## 📝 実装メモ
- 作成日: 2025-07-29
- 対象: PictureBookLendingApp
- 前提: 保育園の絵本にISBNバーコードなし