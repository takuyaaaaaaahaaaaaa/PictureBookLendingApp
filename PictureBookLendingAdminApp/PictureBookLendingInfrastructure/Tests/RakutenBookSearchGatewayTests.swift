import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingInfrastructure

/// RakutenBookSearchGatewayのユニットテスト
///
/// MockURLProtocolでネットワークをモックし、パース・マッピング・エラー処理を
/// 実際のAPI通信なしで検証します。
///
/// MockURLProtocolが静的なハンドラを共有するため、テストは直列実行する。
@Suite(.serialized)
struct RakutenBookSearchGatewayTests {
    
    /// テスト用のアプリID（モック環境では値は問われない）
    private let dummyAppId = "test-application-id"
    
    /// はらぺこあおむしを模したレスポンスJSON
    private func sampleResponseJSON(isbn: String = "9784834000825") -> Data {
        let json = """
            {
              "Items": [
                {
                  "Item": {
                    "title": "はらぺこあおむし",
                    "author": "エリック・カール",
                    "publisherName": "偕成社",
                    "isbn": "\(isbn)",
                    "itemCaption": "ちいさなあおむしが、たくさん食べて…",
                    "salesDate": "1976年05月",
                    "smallImageUrl": "https://example.com/small.jpg?_ex=64x64",
                    "mediumImageUrl": "https://example.com/medium.jpg?_ex=128x128",
                    "largeImageUrl": "https://example.com/large.jpg?_ex=200x200",
                    "size": "絵本",
                    "seriesName": "はらぺこ"
                  }
                }
              ],
              "count": 1
            }
            """
        return Data(json.utf8)
    }
    
    // MARK: - searchBook(by:)
    
    /// 有効なISBNで書籍情報が正しくマッピングされることをテスト
    @Test func searchBookMapsFieldsCorrectly() async throws {
        let session = MockURLProtocol.makeSession { _ in
            (200, self.sampleResponseJSON())
        }
        let gateway = RakutenBookSearchGateway(applicationId: dummyAppId, urlSession: session)
        
        let book = try await gateway.searchBook(by: "978-4-834-00082-5")
        
        #expect(book.title == "はらぺこあおむし")
        #expect(book.author == "エリック・カール")
        #expect(book.isbn13 == "9784834000825")
        #expect(book.publisher == "偕成社")
        #expect(book.publishedDate == "1976年05月")
        #expect(book.description == "ちいさなあおむしが、たくさん食べて…")
        #expect(book.thumbnail == "https://example.com/large.jpg?_ex=200x200")
        #expect(book.smallThumbnail == "https://example.com/small.jpg?_ex=64x64")
        #expect(book.categories == ["絵本"])
        #expect(book.pageCount == nil)
    }
    
    /// 無効なISBN形式ではネットワークを呼ばずに.invalidISBNを投げることをテスト
    @Test func searchBookWithInvalidISBNThrows() async throws {
        let session = MockURLProtocol.makeSession { _ in
            Issue.record("無効なISBNではネットワークを呼ぶべきではない")
            return (200, Data())
        }
        let gateway = RakutenBookSearchGateway(applicationId: dummyAppId, urlSession: session)
        
        await #expect(throws: BookMetadataGatewayError.invalidISBN) {
            try await gateway.searchBook(by: "invalid-isbn")
        }
    }
    
    /// 検索結果が空の場合に.bookNotFoundを投げることをテスト
    @Test func searchBookWithEmptyResultThrowsBookNotFound() async throws {
        let session = MockURLProtocol.makeSession { _ in
            (200, Data(#"{"Items": [], "count": 0}"#.utf8))
        }
        let gateway = RakutenBookSearchGateway(applicationId: dummyAppId, urlSession: session)
        
        await #expect(throws: BookMetadataGatewayError.bookNotFound) {
            try await gateway.searchBook(by: "9789999999991")
        }
    }
    
    /// 404レスポンスを.bookNotFoundとして扱うことをテスト
    @Test func searchBookWith404ThrowsBookNotFound() async throws {
        let session = MockURLProtocol.makeSession { _ in
            (404, Data(#"{"error": "not_found"}"#.utf8))
        }
        let gateway = RakutenBookSearchGateway(applicationId: dummyAppId, urlSession: session)
        
        await #expect(throws: BookMetadataGatewayError.bookNotFound) {
            try await gateway.searchBook(by: "9784834000825")
        }
    }
    
    /// 400レスポンスを.httpErrorとして扱うことをテスト
    @Test func searchBookWith400ThrowsHTTPError() async throws {
        let session = MockURLProtocol.makeSession { _ in
            (400, Data(#"{"error": "wrong_parameter"}"#.utf8))
        }
        let gateway = RakutenBookSearchGateway(applicationId: dummyAppId, urlSession: session)
        
        await #expect(throws: BookMetadataGatewayError.httpError(statusCode: 400)) {
            try await gateway.searchBook(by: "9784834000825")
        }
    }
    
    /// ISBN-13でない場合はisbn13にnilが入ることをテスト
    @Test func searchBookWithNonISBN13ResponseStoresNilISBN() async throws {
        let session = MockURLProtocol.makeSession { _ in
            // レスポンスのisbnがISBN-10（10桁）のケース
            (200, self.sampleResponseJSON(isbn: "4834000826"))
        }
        let gateway = RakutenBookSearchGateway(applicationId: dummyAppId, urlSession: session)
        
        let book = try await gateway.searchBook(by: "9784834000825")
        
        #expect(book.isbn13 == nil)
    }
    
    // MARK: - searchBooks(title:author:)
    
    /// タイトル検索で書籍リストが取得できることをテスト
    @Test func searchBooksByTitleReturnsList() async throws {
        let session = MockURLProtocol.makeSession { _ in
            (200, self.sampleResponseJSON())
        }
        let gateway = RakutenBookSearchGateway(applicationId: dummyAppId, urlSession: session)
        
        let books = try await gateway.searchBooks(title: "はらぺこあおむし", author: nil, maxResults: 20)
        
        #expect(books.count == 1)
        #expect(books.first?.title == "はらぺこあおむし")
    }
    
    /// maxResultsが30を超える場合にhitsが30にクランプされることをテスト
    @Test func searchBooksClampsHitsTo30() async throws {
        let session = MockURLProtocol.makeSession { request in
            let query = request.url?.query ?? ""
            #expect(query.contains("hits=30"))
            #expect(!query.contains("hits=100"))
            return (200, self.sampleResponseJSON())
        }
        let gateway = RakutenBookSearchGateway(applicationId: dummyAppId, urlSession: session)
        
        _ = try await gateway.searchBooks(title: "絵本", author: nil, maxResults: 100)
    }
    
    /// 著者を指定した場合にauthorクエリが付与されることをテスト
    @Test func searchBooksIncludesAuthorQuery() async throws {
        let session = MockURLProtocol.makeSession { request in
            let query = request.url?.query ?? ""
            #expect(query.contains("author="))
            return (200, self.sampleResponseJSON())
        }
        let gateway = RakutenBookSearchGateway(applicationId: dummyAppId, urlSession: session)
        
        _ = try await gateway.searchBooks(title: "ぐりとぐら", author: "なかがわりえこ", maxResults: 20)
    }
}
