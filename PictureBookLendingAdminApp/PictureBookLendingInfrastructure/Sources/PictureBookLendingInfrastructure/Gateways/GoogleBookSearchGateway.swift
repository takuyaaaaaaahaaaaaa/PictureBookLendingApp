import Foundation
import PictureBookLendingDomain

/// Google Books検索ゲートウェイ
/// Google Books API v1を使用して書籍の検索を行います
public struct GoogleBookSearchGateway: BookSearchGatewayProtocol, Sendable {
    
    /// URLSession（テスト時にモック可能）
    private let urlSession: URLSession
    
    /// 初期化
    /// - Parameter urlSession: 使用するURLSession（デフォルトはshared）
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
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
        // 検索クエリの構築
        var query = "intitle:\"\(title)\""
        if let author = author, !author.isEmpty {
            query += "+inauthor:\"\(author)\""
        }
        
        // URLを構築
        guard let url = buildSearchURL(query: query, maxResults: maxResults) else {
            throw BookMetadataGatewayError.unknown
        }
        
        // APIリクエスト実行
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(from: url)
        } catch {
            throw BookMetadataGatewayError.networkError
        }
        
        // HTTPレスポンス検証
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookMetadataGatewayError.unknown
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BookMetadataGatewayError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // JSONデコード
        let volumesResponse: VolumesResponse
        do {
            volumesResponse = try JSONDecoder().decode(VolumesResponse.self, from: data)
        } catch {
            throw BookMetadataGatewayError.decodingError
        }
        
        // 結果をBookモデルにマッピング
        guard let items = volumesResponse.items, !items.isEmpty else {
            throw BookMetadataGatewayError.bookNotFound
        }
        
        return items.map { mapToBook(volume: $0) }
    }
    
    // MARK: - BookSearchGatewayProtocol Implementation
    
    /// 指定されたISBNで書籍を検索する
    /// - Parameter isbn: 検索する書籍のISBN-13またはISBN-10
    /// - Returns: ドメインモデルとしてのBook
    /// - Throws: BookMetadataGatewayError
    public func searchBook(by isbn: String) async throws -> Book {
        let normalizedISBN = ISBNValidator.normalize(isbn)
        
        // ISBN形式検証
        guard ISBNValidator.isValidISBN(normalizedISBN) else {
            throw BookMetadataGatewayError.invalidISBN
        }
        
        // URLを構築
        guard let url = buildURL(for: normalizedISBN) else {
            throw BookMetadataGatewayError.unknown
        }
        
        // APIリクエスト実行
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(from: url)
        } catch {
            throw BookMetadataGatewayError.networkError
        }
        
        // HTTPレスポンス検証
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookMetadataGatewayError.unknown
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BookMetadataGatewayError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // JSONデコード
        let volumesResponse: VolumesResponse
        do {
            volumesResponse = try JSONDecoder().decode(VolumesResponse.self, from: data)
        } catch {
            throw BookMetadataGatewayError.decodingError
        }
        
        // 結果検証とベストマッチ選択
        guard let items = volumesResponse.items, !items.isEmpty else {
            throw BookMetadataGatewayError.bookNotFound
        }
        
        let bestMatch = selectBestMatch(items: items, targetISBN: normalizedISBN)
        return mapToBook(volume: bestMatch)
    }
    
    /// 検索クエリ用のGoogle Books API URLを構築する
    /// - Parameters:
    ///   - query: 検索クエリ
    ///   - maxResults: 最大取得件数
    /// - Returns: 構築されたURL
    private func buildSearchURL(query: String, maxResults: Int) -> URL? {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "printType", value: "books"),
            URLQueryItem(name: "langRestrict", value: "ja"),
            URLQueryItem(name: "orderBy", value: "relevance"),
            URLQueryItem(
                name: "fields",
                value:
                    "items(volumeInfo/title,volumeInfo/authors,volumeInfo/publisher,volumeInfo/publishedDate,volumeInfo/description,volumeInfo/pageCount,volumeInfo/categories,volumeInfo/imageLinks,volumeInfo/industryIdentifiers,volumeInfo/infoLink)"
            ),
        ]

        // APIキーが設定されている場合は追加
        if let apiKey = Secrets.googleBooksAPIKey, !apiKey.isEmpty {
            queryItems.append(URLQueryItem(name: "key", value: apiKey))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    /// Google Books API URLを構築する
    /// - Parameter isbn: 正規化されたISBN
    /// - Returns: 構築されたURL
    private func buildURL(for isbn: String) -> URL? {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: "isbn:\(isbn)"),
            URLQueryItem(name: "maxResults", value: "5"),
            URLQueryItem(name: "printType", value: "books"),
            URLQueryItem(name: "langRestrict", value: "ja"),
            URLQueryItem(name: "projection", value: "full"),
            URLQueryItem(
                name: "fields",
                value:
                    "items(volumeInfo/title,volumeInfo/authors,volumeInfo/publisher,volumeInfo/publishedDate,volumeInfo/description,volumeInfo/pageCount,volumeInfo/categories,volumeInfo/imageLinks,volumeInfo/industryIdentifiers,volumeInfo/infoLink)"
            ),
        ]

        // APIキーが設定されている場合は追加
        if let apiKey = Secrets.googleBooksAPIKey, !apiKey.isEmpty {
            queryItems.append(URLQueryItem(name: "key", value: apiKey))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    /// 複数の候補から最適なマッチを選択する
    /// - Parameters:
    ///   - items: Google Books APIからの候補リスト
    ///   - targetISBN: 検索対象のISBN
    /// - Returns: 最適なボリューム
    private func selectBestMatch(items: [Volume], targetISBN: String) -> Volume {
        let normalizedTarget = ISBNValidator.normalize(targetISBN)
        
        // ISBN-13完全一致を最優先
        if let exactISBN13Match = items.first(where: { volume in
            volume.volumeInfo.industryIdentifiers?.contains { identifier in
                identifier.type == "ISBN_13"
                    && ISBNValidator.normalize(identifier.identifier) == normalizedTarget
            } ?? false
        }) {
            return exactISBN13Match
        }
        
        // ISBN-10完全一致を次優先
        if let exactISBN10Match = items.first(where: { volume in
            volume.volumeInfo.industryIdentifiers?.contains { identifier in
                identifier.type == "ISBN_10"
                    && ISBNValidator.normalize(identifier.identifier) == normalizedTarget
            } ?? false
        }) {
            return exactISBN10Match
        }
        
        // 完全一致がない場合は最初の結果を返す
        return items[0]
    }
    
    /// Google Books APIのレスポンスをBookドメインモデルにマッピングする
    /// - Parameter volume: Google Books APIのボリューム
    /// - Returns: Bookドメインモデル
    private func mapToBook(volume: Volume) -> Book {
        let volumeInfo = volume.volumeInfo
        
        // 小さなサムネイル画像URLの処理
        let smallThumbnail: String? = {
            guard let urlString = volumeInfo.imageLinks?.smallThumbnail else { return nil }
            return urlString.replacingOccurrences(of: "http://", with: "https://")
        }()

        // 通常サイズのサムネイル画像URLの処理
        let thumbnail: String? = {
            guard let urlString = volumeInfo.imageLinks?.thumbnail else { return nil }
            return urlString.replacingOccurrences(of: "http://", with: "https://")
        }()

        // ISBN情報の抽出
        let isbn13 = volumeInfo.industryIdentifiers?.first { $0.type == "ISBN_13" }?.identifier
        
        return Book(
            title: volumeInfo.title ?? "（タイトル未取得）",
            author: volumeInfo.authors?.joined(separator: ", ") ?? "（著者未取得）",
            isbn13: isbn13,
            publisher: volumeInfo.publisher,
            publishedDate: volumeInfo.publishedDate,
            description: volumeInfo.description,
            smallThumbnail: smallThumbnail,
            thumbnail: thumbnail,
            targetAge: nil,  // APIからは取得できないため、後でユーザーが設定
            pageCount: volumeInfo.pageCount,
            categories: volumeInfo.categories ?? []
        )
    }
}
