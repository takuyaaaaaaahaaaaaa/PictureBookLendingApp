import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingInfrastructure

/// GoogleBookSearchGatewayテストケース
///
/// 実際のGoogle Books APIを使用した統合テストです
/// APIキーが設定されている必要があります
@Suite(.tags(.integrationTest))
struct GoogleBookSearchGatewayTests {
    
    private let gateway = GoogleBookSearchGateway()
    
    /// 有効なISBNで書籍情報が取得できることをテスト
    @Test(.tags(.integrationTest)) func fetchBookWithValidISBN() async throws {
        // はらぺこあおむしのISBN-13
        let isbn = "978-4834000825"
        
        let book = try await gateway.searchBook(by: isbn)
        
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
    @Test(.tags(.integrationTest)) func fetchBookWithAnotherValidISBN() async throws {
        let isbn = "9784061272743"
        
        let book = try await gateway.searchBook(by: isbn)
        
        #expect(!book.title.isEmpty)
        #expect(!book.author.isEmpty)
        
        print("取得した書籍情報（2冊目）:")
        print("タイトル: \(book.title)")
        print("著者: \(book.author)")
    }
    
    /// 無効なISBN形式でエラーが発生することをテスト
    @Test(.tags(.integrationTest)) func fetchBookWithInvalidISBNFormat() async throws {
        let invalidISBN = "invalid-isbn"
        
        await #expect(throws: BookMetadataGatewayError.invalidISBN) {
            try await gateway.searchBook(by: invalidISBN)
        }
    }
    
    /// 存在しないが有効な形式のISBNでエラーが発生することをテスト
    @Test(.tags(.integrationTest)) func fetchBookWithNonExistentISBN() async throws {
        let nonExistentISBN = "9789999999991"  // 有効なISBN-13形式だが存在しない
        
        await #expect(throws: BookMetadataGatewayError.bookNotFound) {
            try await gateway.searchBook(by: nonExistentISBN)
        }
    }
    
    /// ISBN-10形式でも動作することをテスト
    @Test(.tags(.integrationTest)) func fetchBookWithISBN10() async throws {
        let isbn10 = "4834000826"  // はらぺこあおむしの有効なISBN-10
        
        let book = try await gateway.searchBook(by: isbn10)
        
        #expect(!book.title.isEmpty)
        #expect(!book.author.isEmpty)
        
        print("ISBN-10で取得した書籍情報:")
        print("タイトル: \(book.title)")
    }
    
    /// ハイフン付きISBNでも動作することをテスト
    @Test(.tags(.integrationTest)) func fetchBookWithHyphenatedISBN() async throws {
        let hyphenatedISBN = "978-4-83-400082-5"  // はらぺこあおむしの正しいハイフン付きISBN
        
        let book = try await gateway.searchBook(by: hyphenatedISBN)
        
        #expect(!book.title.isEmpty)
        #expect(!book.author.isEmpty)
        
        print("ハイフン付きISBNで取得した書籍情報:")
        print("タイトル: \(book.title)")
    }
    
    /// タイトルで書籍を検索するテスト
    @Test(.tags(.integrationTest)) func searchBooksByTitle() async throws {
        let title = "ぐりとぐら"
        
        let books = try await gateway.searchBooks(title: title, author: nil, maxResults: 20)
        
        // 結果が取得できることを確認
        #expect(!books.isEmpty)
        
        print("「\(title)」の検索結果（\(books.count)件）:")
        for (index, book) in books.prefix(3).enumerated() {
            print("\(index + 1). \(book.title) - \(book.author)")
        }
    }
    
    /// タイトルと著者で書籍を検索するテスト
    @Test(.tags(.integrationTest)) func searchBooksByTitleAndAuthor() async throws {
        let title = "ぐりとぐら"
        let author = "なかがわりえこ"
        
        let books = try await gateway.searchBooks(title: title, author: author, maxResults: 20)
        
        // 結果が取得できることを確認
        #expect(!books.isEmpty)
        
        print("「\(title)」「\(author)」の検索結果（\(books.count)件）:")
        for (index, book) in books.prefix(3).enumerated() {
            print("\(index + 1). \(book.title) - \(book.author)")
        }
    }
    
    /// 検索結果が見つからない場合のテスト
    @Test(.tags(.integrationTest)) func searchBooksNotFound() async throws {
        let title = "存在しない絵本のタイトル12345"
        
        await #expect(throws: BookMetadataGatewayError.bookNotFound) {
            try await gateway.searchBooks(title: title, author: nil, maxResults: 20)
        }
    }
    
    /// 複数の有名絵本を検索するテスト
    @Test(.tags(.integrationTest)) func searchMultipleFamousBooks() async throws {
        let testCases = [
            ("はらぺこあおむし", "エリック・カール"),
            ("100万回生きたねこ", "佐野洋子"),
            ("スイミー", "レオ・レオニ"),
        ]
        
        for (title, author) in testCases {
            let books = try await gateway.searchBooks(title: title, author: author, maxResults: 20)
            
            #expect(!books.isEmpty)
            print("「\(title)」の検索結果: \(books.first?.title ?? "不明")")
        }
    }
    
    /// パフォーマンステスト（3秒以内で応答）
    @Test(.tags(.integrationTest)) func fetchBookPerformance() async throws {
        let isbn = "9784834000825"  // はらぺこあおむしの有効なISBN
        let startTime = Date()
        
        _ = try await gateway.searchBook(by: isbn)
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        print("API応答時間: \(String(format: "%.2f", elapsedTime))秒")
        
        // 3秒以内で応答することを確認
        #expect(elapsedTime < 3.0)
    }
    
    /// BookSearchGatewayProtocolの動作テスト
    @Test(.tags(.integrationTest)) func bookSearchGatewayProtocolIntegration() async throws {
        let gateway: BookSearchGatewayProtocol = GoogleBookSearchGateway()
        let isbn = "9784834000825"  // はらぺこあおむしの有効なISBN
        
        let book = try await gateway.searchBook(by: isbn)
        
        #expect(!book.title.isEmpty)
        #expect(!book.author.isEmpty)
        
        print("BookSearchGatewayProtocol経由で取得:")
        print("タイトル: \(book.title)")
    }
}
