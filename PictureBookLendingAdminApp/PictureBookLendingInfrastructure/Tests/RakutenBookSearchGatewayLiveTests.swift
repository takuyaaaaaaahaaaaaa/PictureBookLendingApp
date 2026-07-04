import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingInfrastructure

/// RakutenBookSearchGatewayのライブ統合テスト
///
/// 実際の楽天ブックスAPIを使用します。
/// 環境変数 RUN_LIVE_API_TESTS=1 と RAKUTEN_APPLICATION_ID=<アプリID> を
/// 設定した場合のみ実行されます。
///
/// 実行例:
///   RUN_LIVE_API_TESTS=1 RAKUTEN_APPLICATION_ID=xxxx swift test
@Suite(.tags(.integrationTest), .rakutenLiveAPITest)
struct RakutenBookSearchGatewayLiveTests {
    
    private var gateway: RakutenBookSearchGateway {
        RakutenBookSearchGateway(applicationId: ProcessInfo.processInfo.rakutenApplicationId)
    }
    
    /// 有効なISBNで書籍情報が取得できることをテスト
    @Test func fetchBookWithValidISBN() async throws {
        // はらぺこあおむしのISBN-13
        let book = try await gateway.searchBook(by: "9784834000825")
        
        #expect(!book.title.isEmpty)
        #expect(book.thumbnail != nil)
        
        print("取得した書籍情報:")
        print("タイトル: \(book.title)")
        print("著者: \(book.author ?? "不明")")
        print("出版社: \(book.publisher ?? "不明")")
        print("書影: \(book.thumbnail ?? "なし")")
    }
    
    /// タイトルで書籍を検索できることをテスト
    @Test func searchBooksByTitle() async throws {
        let books = try await gateway.searchBooks(title: "ぐりとぐら", author: nil, maxResults: 20)
        
        #expect(!books.isEmpty)
        
        print("「ぐりとぐら」の検索結果（\(books.count)件）:")
        for book in books.prefix(3) {
            print("- \(book.title) / \(book.author ?? "不明")")
        }
    }
}
