# 絵本登録機能（ISBN画像入力→Google Books API連携）実装プラン

## 📋 概要
既存のBookエンティティを拡張し、ISBN画像入力とGoogle Books APIを使った自動情報取得機能を追加します。

## 🏗️ アーキテクチャ設計

### 1. Domainレイヤーの拡張
- `Book.swift`: ISBN13フィールド、publisher、publishedDate、description、thumbnailURL等を追加
- `BookMetadataServiceProtocol`: 外部APIからの書誌情報取得を抽象化
- `BookRepositoryProtocol`: 既存のDBアクセス（変更なし）

### 2. Infrastructureレイヤーの追加
- `GoogleBooksAPIClient`: Google Books APIとの通信を担当
- `BookMetadataServiceLive`: `BookMetadataServiceProtocol`の実装
- `ISBNScanner`: Vision/AVFoundationを使ったISBN読み取り機能
- `BookRepositoryLive`: 既存のDB操作（変更なし）

### 3. Modelレイヤーの拡張  
- `BookModel`: ISBN登録、書誌情報自動取得メソッドを追加
- `BookMetadataServiceProtocol`への依存を注入

### 4. UIレイヤーの追加
- `ISBNScannerView`: バーコード/OCRスキャナー画面
- `BookRegistrationView`: スキャン→API取得→登録の統合画面

### 5. Appレイヤーの追加
- `BookRegistrationContainerView`: 状態管理とビジネスロジック

## 📱 実装段階

### Phase 1: Domainレイヤー拡張
1. `Book.swift`にISBN13、publisher、description等のフィールド追加
2. `BookMetadataServiceProtocol`定義（外部API用）
3. ISBN13バリデーション機能実装

### Phase 2: GoogleBooksAPIClient実装
1. `GoogleBooksAPIClient`実装（async/await、エラーハンドリング）
2. `BookMetadataServiceLive`実装（Google Books API統合）

### Phase 3: API統合テスト・検証
1. `GoogleBooksAPIClientTests`作成（単体テスト）
2. 実際のAPIキーを使用した統合テスト実装
3. 複数のISBNパターンでのテスト実行・検証
4. エラーケース（存在しないISBN、ネットワークエラー等）のテスト

### Phase 4: Infrastructure完成
1. `ISBNScanner`実装（AVFoundation + Vision framework）
2. その他Infrastructure層の完成

### Phase 5: Model/UI実装
1. `BookModel`の拡張（`BookMetadataServiceProtocol`注入、ISBN登録フロー）
2. `ISBNScannerView`の実装（SwiftUI + UIViewRepresentable）
3. `BookRegistrationView`の実装

### Phase 6: Container統合
1. `BookRegistrationContainerView`実装
2. 既存の`BookFormContainerView`との統合
3. ナビゲーションフローの追加

### Phase 7: 最終テスト・最適化
1. 各レイヤーの単体テスト追加
2. オフライン対応の強化
3. UX改善（ローディング、エラーハンドリング）

## 🔧 技術仕様

### 責務分離
- **BookRepositoryProtocol**: ローカルDB操作のみ
- **BookMetadataServiceProtocol**: 外部API通信のみ
- **BookModel**: 両者を協調させるビジネスロジック

### ISBN読み取り
- **第一候補**: AVCaptureMetadataOutput（EAN-13バーコード）
- **フォールバック**: Vision framework OCR
- **検証**: ISBN-13チェックサム検証

### API統合
- **エンドポイント**: Google Books API v1
- **認証**: APIキー（Bundle ID制限）
- **オフライン対応**: ローカルキャッシュ + 同期キュー

### API検証テスト仕様
- **テスト対象ISBN**: 9784041026221（有名な絵本）、9784061272743（存在確認済み）
- **エラーテスト**: 存在しないISBN、不正なISBN形式
- **APIレスポンス検証**: title、authors、publisher等の必須フィールド
- **パフォーマンステスト**: レスポンス時間測定

### データフロー
1. ISBN画像スキャン
2. ISBN検証
3. `BookMetadataServiceProtocol`でGoogle Books API呼び出し
4. メタデータ取得・マッピング
5. ユーザー確認・編集
6. `BookRepositoryProtocol`でBook登録

## ⚠️ 注意点
- Phase 3のAPI検証では実際のAPIキーが必要
- 完全オフライン運用への対応（同期キュー実装）
- プライバシー保護（ISBN以外の情報は外部送信しない）
- 既存のBookFormとの統合を慎重に実施
- Vision/AVFoundation使用のためカメラ権限が必要

## 🧪 テスト戦略
- TDD原則に従い、Domain層から段階的にテスト実装
- Phase 3で実APIを使った統合テスト実行
- Mock BookMetadataServiceProtocol/BookRepositoryProtocolでUI層のテスト
- ISBN検証ロジックの充実したテスト
- オフライン/オンライン切り替えシナリオのテスト

## 📝 実装メモ
- 作成日: 2025-07-28
- 対象: PictureBookLendingApp
- 担当者: Claude Code + o3 MCP連携