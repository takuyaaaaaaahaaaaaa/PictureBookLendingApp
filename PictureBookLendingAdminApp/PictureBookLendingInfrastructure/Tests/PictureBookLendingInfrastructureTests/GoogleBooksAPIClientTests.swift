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
    @Test func fetchBookWithValidISBN() async throws {
        // はらぺこあおむしのISBN-13
        let isbn = "978-4834000825"
        
        let book = try await apiClient.fetchBook(for: isbn)
        
        // 基本情報が取得できていることを確認
        #expect(!book.title.isEmpty)
        #expect(!book.author.isEmpty)
        #expect(book.isbn13 != nil)
        
        print("取得した書籍情報:")
        print("タイトル: \(book.title)")
        print("著者: \(book.author)")
        print("出版社: \(book.publisher ?? "不明")")
        print("ISBN-13: \(book.isbn13 ?? "なし")")
        print("ページ数: \(book.pageCount?.description ?? "不明")")
    }
    
    /// 別の有効なISBNでもテスト（ぐりとぐら）
    @Test func fetchBookWithAnotherValidISBN() async throws {
        let isbn = "9784061272743"
        
        let book = try await apiClient.fetchBook(for: isbn)
        
        #expect(!book.title.isEmpty)
        #expect(!book.author.isEmpty)
        
        print("取得した書籍情報（2冊目）:")
        print("タイトル: \(book.title)")
        print("著者: \(book.author)")
    }
    
    /// 無効なISBN形式でエラーが発生することをテスト
    @Test func fetchBookWithInvalidISBNFormat() async throws {
        let invalidISBN = "invalid-isbn"
        
        await #expect(throws: BookMetadataGatewayError.invalidISBN) {
            try await apiClient.fetchBook(for: invalidISBN)
        }
    }
    
    /// 存在しないが有効な形式のISBNでエラーが発生することをテスト
    @Test func fetchBookWithNonExistentISBN() async throws {
        let nonExistentISBN = "9789999999991"  // 有効なISBN-13形式だが存在しない
        
        await #expect(throws: BookMetadataGatewayError.bookNotFound) {
            try await apiClient.fetchBook(for: nonExistentISBN)
        }
    }
    
    /// ISBN-10形式でも動作することをテスト
    @Test func fetchBookWithISBN10() async throws {
        let isbn10 = "4834000826"  // はらぺこあおむしの有効なISBN-10
        
        let book = try await apiClient.fetchBook(for: isbn10)
        
        #expect(!book.title.isEmpty)
        #expect(!book.author.isEmpty)
        
        print("ISBN-10で取得した書籍情報:")
        print("タイトル: \(book.title)")
    }
    
    /// ハイフン付きISBNでも動作することをテスト
    @Test func fetchBookWithHyphenatedISBN() async throws {
        let hyphenatedISBN = "978-4-83-400082-5"  // はらぺこあおむしの正しいハイフン付きISBN
        
        let book = try await apiClient.fetchBook(for: hyphenatedISBN)
        
        #expect(!book.title.isEmpty)
        #expect(!book.author.isEmpty)
        
        print("ハイフン付きISBNで取得した書籍情報:")
        print("タイトル: \(book.title)")
    }
    
    /// パフォーマンステスト（3秒以内で応答）
    @Test func fetchBookPerformance() async throws {
        let isbn = "9784834000825"  // はらぺこあおむしの有効なISBN
        let startTime = Date()
        
        _ = try await apiClient.fetchBook(for: isbn)
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        print("API応答時間: \(String(format: "%.2f", elapsedTime))秒")
        
        // 3秒以内で応答することを確認
        #expect(elapsedTime < 3.0)
    }
    
    /// BookMetadataGatewayの動作テスト
    @Test func bookMetadataGatewayIntegration() async throws {
        let gateway = BookMetadataGateway()
        let isbn = "9784834000825"  // はらぺこあおむしの有効なISBN
        
        let book = try await gateway.getBook(by: isbn)
        
        #expect(!book.title.isEmpty)
        #expect(!book.author.isEmpty)
        
        print("BookMetadataGateway経由で取得:")
        print("タイトル: \(book.title)")
    }
}
