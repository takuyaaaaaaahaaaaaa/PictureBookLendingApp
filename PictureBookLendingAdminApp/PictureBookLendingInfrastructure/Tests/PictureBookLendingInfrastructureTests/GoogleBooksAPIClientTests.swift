import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingInfrastructure

/// GoogleBooksAPIClientテストケース
///
/// 実際のGoogle Books APIを使用した統合テストです
/// APIキーが設定されている必要があります
struct GoogleBooksAPIClientTests {
    
    private let apiClient = GoogleBooksAPIClient()
    
    /// 有効なISBNで書籍情報が取得できることをテスト
    @Test func fetchMetadataWithValidISBN() async throws {
        // はらぺこあおむしのISBN-13
        let isbn = "978-4834000825"
        
        let metadata = try await apiClient.fetchMetadata(for: isbn)
        
        // 基本情報が取得できていることを確認
        #expect(!metadata.title.isEmpty)
        #expect(!metadata.authors.isEmpty)
        #expect(metadata.isbn13 != nil || metadata.isbn10 != nil)
        
        print("取得した書籍情報:")
        print("タイトル: \(metadata.title)")
        print("著者: \(metadata.authors.joined(separator: ", "))")
        print("出版社: \(metadata.publisher ?? "不明")")
        print("ISBN-13: \(metadata.isbn13 ?? "なし")")
        print("ISBN-10: \(metadata.isbn10 ?? "なし")")
    }
    
    /// 別の有効なISBNでもテスト（ぐりとぐら）
    @Test func fetchMetadataWithAnotherValidISBN() async throws {
        let isbn = "9784061272743"
        
        let metadata = try await apiClient.fetchMetadata(for: isbn)
        
        #expect(!metadata.title.isEmpty)
        #expect(!metadata.authors.isEmpty)
        
        print("取得した書籍情報（2冊目）:")
        print("タイトル: \(metadata.title)")
        print("著者: \(metadata.authors.joined(separator: ", "))")
    }
    
    /// 無効なISBN形式でエラーが発生することをテスト
    @Test func fetchMetadataWithInvalidISBNFormat() async throws {
        let invalidISBN = "invalid-isbn"
        
        await #expect(throws: BookMetadataServiceError.invalidISBN) {
            try await apiClient.fetchMetadata(for: invalidISBN)
        }
    }
    
    /// 存在しないが有効な形式のISBNでエラーが発生することをテスト
    @Test func fetchMetadataWithNonExistentISBN() async throws {
        let nonExistentISBN = "9789999999991"  // 有効なISBN-13形式だが存在しない
        
        await #expect(throws: BookMetadataServiceError.bookNotFound) {
            try await apiClient.fetchMetadata(for: nonExistentISBN)
        }
    }
    
    /// ISBN-10形式でも動作することをテスト
    @Test func fetchMetadataWithISBN10() async throws {
        let isbn10 = "4834000826"  // はらぺこあおむしの有効なISBN-10
        
        let metadata = try await apiClient.fetchMetadata(for: isbn10)
        
        #expect(!metadata.title.isEmpty)
        #expect(!metadata.authors.isEmpty)
        
        print("ISBN-10で取得した書籍情報:")
        print("タイトル: \(metadata.title)")
    }
    
    /// ハイフン付きISBNでも動作することをテスト
    @Test func fetchMetadataWithHyphenatedISBN() async throws {
        let hyphenatedISBN = "978-4-83-400082-5"  // はらぺこあおむしの正しいハイフン付きISBN
        
        let metadata = try await apiClient.fetchMetadata(for: hyphenatedISBN)
        
        #expect(!metadata.title.isEmpty)
        #expect(!metadata.authors.isEmpty)
        
        print("ハイフン付きISBNで取得した書籍情報:")
        print("タイトル: \(metadata.title)")
    }
    
    /// パフォーマンステスト（3秒以内で応答）
    @Test func fetchMetadataPerformance() async throws {
        let isbn = "9784834000825"  // はらぺこあおむしの有効なISBN
        let startTime = Date()
        
        _ = try await apiClient.fetchMetadata(for: isbn)
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        print("API応答時間: \(String(format: "%.2f", elapsedTime))秒")
        
        // 3秒以内で応答することを確認
        #expect(elapsedTime < 3.0)
    }
    
    /// BookMetadataServiceLiveの動作テスト
    @Test func bookMetadataServiceLiveIntegration() async throws {
        let service = BookMetadataServiceLive()
        let isbn = "9784834000825"  // はらぺこあおむしの有効なISBN
        
        let metadata = try await service.fetchMetadata(for: isbn)
        
        #expect(!metadata.title.isEmpty)
        #expect(!metadata.authors.isEmpty)
        
        print("BookMetadataServiceLive経由で取得:")
        print("タイトル: \(metadata.title)")
    }
}
