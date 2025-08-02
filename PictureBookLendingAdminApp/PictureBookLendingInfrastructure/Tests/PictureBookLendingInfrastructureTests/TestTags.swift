import Testing

/// テストタグの定義
extension Tag {
    /// 統合テスト（外部APIを使用するテスト）
    /// CI/CD環境では除外される
    @Tag static var integrationTest: Self
}
