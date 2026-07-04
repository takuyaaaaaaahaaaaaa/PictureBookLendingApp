import Foundation
import PictureBookLendingDomain

/// 楽天ブックス書籍検索ゲートウェイ
///
/// Rakuten Books Book Search API (version:2017-04-04) を使用して書籍の検索を行います。
/// 利用には楽天ウェブサービスのアプリID（applicationId）が必要です。
public struct RakutenBookSearchGateway: BookSearchGatewayProtocol, Sendable {
    
    /// APIのベースURL
    private static let baseURL =
        "https://openapi.rakuten.co.jp/services/api/BooksBook/Search/20170404"
    
    /// hitsパラメータの最大値（APIの制約）
    private static let maxHits = 30
    
    /// URLSession（テスト時にモック可能）
    private let urlSession: URLSession
    
    /// 楽天ウェブサービスのアプリID
    private let applicationId: String
    
    /// 初期化
    /// - Parameters:
    ///   - applicationId: 楽天ウェブサービスのアプリID
    ///   - urlSession: 使用するURLSession（デフォルトはshared）
    public init(applicationId: String, urlSession: URLSession = .shared) {
        self.applicationId = applicationId
        self.urlSession = urlSession
    }
    
    // MARK: - BookSearchGatewayProtocol Implementation
    
    /// 指定されたISBNで書籍を検索する
    /// - Parameter isbn: 検索する書籍のISBN-13またはISBN-10
    /// - Returns: ドメインモデルとしてのBook
    /// - Throws: BookMetadataGatewayError
    public func searchBook(by isbn: String) async throws -> Book {
        let normalizedISBN = ISBNValidator.normalize(isbn)
        
        guard ISBNValidator.isValidISBN(normalizedISBN) else {
            throw BookMetadataGatewayError.invalidISBN
        }
        
        guard let url = buildURL(queryItems: [URLQueryItem(name: "isbn", value: normalizedISBN)])
        else {
            throw BookMetadataGatewayError.unknown
        }
        
        let items = try await fetchItems(from: url)
        return mapToBook(item: items[0])
    }
    
    /// タイトルと著者名で書籍を検索する
    /// - Parameters:
    ///   - title: 書籍のタイトル
    ///   - author: 著者名（オプション）
    ///   - maxResults: 最大取得件数
    /// - Returns: 検索結果の書籍リスト
    /// - Throws: BookMetadataGatewayError
    public func searchBooks(title: String, author: String?, maxResults: Int) async throws -> [Book]
    {
        let hits = max(1, min(maxResults, Self.maxHits))
        
        var queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "hits", value: String(hits)),
        ]
        if let author, !author.isEmpty {
            queryItems.append(URLQueryItem(name: "author", value: author))
        }
        
        guard let url = buildURL(queryItems: queryItems) else {
            throw BookMetadataGatewayError.unknown
        }
        
        let items = try await fetchItems(from: url)
        return items.map(mapToBook(item:))
    }
    
    // MARK: - Private Helpers
    
    /// 共通クエリを付与してAPI URLを構築する
    /// - Parameter queryItems: 検索条件のクエリアイテム
    /// - Returns: 構築されたURL
    private func buildURL(queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(string: Self.baseURL)
        components?.queryItems =
            [
                URLQueryItem(name: "applicationId", value: applicationId),
                URLQueryItem(name: "format", value: "json"),
                URLQueryItem(name: "booksGenreId", value: "001003"),  // 絵本・児童書・図鑑
            ] + queryItems
        return components?.url
    }
    
    /// APIを呼び出して書籍アイテムのリストを取得する
    /// - Parameter url: リクエストURL
    /// - Returns: 空でない書籍アイテムのリスト
    /// - Throws: BookMetadataGatewayError
    private func fetchItems(from url: URL) async throws -> [RakutenBookItem] {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(from: url)
        } catch {
            throw BookMetadataGatewayError.networkError
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookMetadataGatewayError.unknown
        }
        
        // 楽天APIは該当書籍が無い場合に404を返すため、bookNotFoundとして扱う
        if httpResponse.statusCode == 404 {
            throw BookMetadataGatewayError.bookNotFound
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BookMetadataGatewayError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let booksResponse: RakutenBooksResponse
        do {
            booksResponse = try JSONDecoder().decode(RakutenBooksResponse.self, from: data)
        } catch {
            throw BookMetadataGatewayError.decodingError
        }
        
        guard let items = booksResponse.items?.map(\.item), !items.isEmpty else {
            throw BookMetadataGatewayError.bookNotFound
        }
        
        return items
    }
    
    /// 楽天APIの書籍情報をBookドメインモデルにマッピングする
    /// - Parameter item: 楽天APIの書籍情報
    /// - Returns: Bookドメインモデル
    private func mapToBook(item: RakutenBookItem) -> Book {
        // ISBN-13のみをドメインモデルに保持する
        let isbn13: String? = {
            guard let isbn = item.isbn else { return nil }
            let normalized = ISBNValidator.normalize(isbn)
            return ISBNValidator.isValidISBN13(normalized) ? normalized : nil
        }()

        // 書影URL（大 → 中 を優先、小サムネイルは 小 → 中）
        let thumbnail = item.largeImageUrl?.nonEmpty ?? item.mediumImageUrl?.nonEmpty
        let smallThumbnail = item.smallImageUrl?.nonEmpty ?? item.mediumImageUrl?.nonEmpty
        
        // 書籍サイズ（"絵本"等）をカテゴリとして扱う
        let categories = [item.size?.nonEmpty].compactMap { $0 }
        
        return Book(
            title: item.title?.nonEmpty ?? "（タイトル未取得）",
            author: item.author?.nonEmpty,
            isbn13: isbn13,
            publisher: item.publisherName?.nonEmpty,
            publishedDate: item.salesDate?.nonEmpty,
            description: item.itemCaption?.nonEmpty,
            smallThumbnail: smallThumbnail,
            thumbnail: thumbnail,
            targetAge: nil,  // APIからは取得できないため、後でユーザーが設定
            pageCount: nil,  // 楽天APIはページ数を提供しない
            categories: categories,
            managementNumber: nil
        )
    }
}

extension String {
    /// 空文字列の場合はnilを返す
    fileprivate var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
