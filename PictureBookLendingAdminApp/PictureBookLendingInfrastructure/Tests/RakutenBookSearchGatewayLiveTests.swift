import Foundation
import ImageIO
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingInfrastructure

/// RakutenBookSearchGatewayのライブ統合テスト
///
/// 実際の楽天ブックスAPIを使用します。
/// 環境変数 RUN_LIVE_API_TESTS=1 と RAKUTEN_APPLICATION_ID=<アプリID> と
/// RAKUTEN_ACCESS_KEY=<アクセスキー> を設定した場合のみ実行されます。
///
/// 実行例:
///   RUN_LIVE_API_TESTS=1 RAKUTEN_APPLICATION_ID=xxxx RAKUTEN_ACCESS_KEY=yyyy swift test
@Suite(.tags(.integrationTest), .rakutenLiveAPITest)
struct RakutenBookSearchGatewayLiveTests {
    
    private var gateway: RakutenBookSearchGateway {
        RakutenBookSearchGateway(
            applicationId: ProcessInfo.processInfo.rakutenApplicationId,
            accessKey: ProcessInfo.processInfo.rakutenAccessKey)
    }
    
    /// 有効なISBNで書籍情報が取得できることをテスト
    @Test func fetchBookWithValidISBN() async throws {
        // 公開書籍「ぐりとぐら」のISBN-13
        let book = try await gateway.searchBook(by: "9784834000825")
        
        #expect(!book.title.isEmpty)
        #expect(book.thumbnail != nil)
        let imageURLs = Set([book.thumbnail, book.smallThumbnail].compactMap { $0 })
        #expect(!imageURLs.isEmpty)
        for source in imageURLs {
            let url = try #require(URL(string: source))
            let (data, response) = try await URLSession.shared.data(from: url)
            #expect((response as? HTTPURLResponse)?.statusCode == 200)
            let imageSource = try #require(CGImageSourceCreateWithData(data as CFData, nil))
            let image = try #require(CGImageSourceCreateImageAtIndex(imageSource, 0, nil))
            #expect(image.width > 1 && image.height > 1)
            print("書影取得・画像デコード成功: \(image.width)×\(image.height), \(data.count) bytes")
        }

        
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
