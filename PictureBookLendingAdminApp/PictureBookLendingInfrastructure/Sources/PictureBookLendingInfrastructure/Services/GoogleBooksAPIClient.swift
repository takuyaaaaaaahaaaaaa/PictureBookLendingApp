import Foundation
import PictureBookLendingDomain

/// Google Books APIクライアント
/// Google Books API v1を使用して書籍の詳細情報を取得します
public struct GoogleBooksAPIClient {
    
    /// URLSession（テスト時にモック可能）
    private let urlSession: URLSession
    
    /// 初期化
    /// - Parameter urlSession: 使用するURLSession（デフォルトはshared）
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    /// ISBNから書籍情報を取得する
    /// - Parameter isbn: ISBN-13またはISBN-10
    /// - Returns: 書籍メタデータ
    /// - Throws: BookMetadataServiceError
    public func fetchMetadata(for isbn: String) async throws -> BookMetadata {
        let normalizedISBN = ISBNValidator.normalize(isbn)
        
        // ISBN形式検証
        guard ISBNValidator.isValidISBN(normalizedISBN) else {
            throw BookMetadataServiceError.invalidISBN
        }
        
        // URLを構築
        guard let url = buildURL(for: normalizedISBN) else {
            throw BookMetadataServiceError.unknown
        }
        
        // APIリクエスト実行
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(from: url)
        } catch {
            throw BookMetadataServiceError.networkError
        }
        
        // HTTPレスポンス検証
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookMetadataServiceError.unknown
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BookMetadataServiceError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // JSONデコード
        let volumesResponse: VolumesResponse
        do {
            volumesResponse = try JSONDecoder().decode(VolumesResponse.self, from: data)
        } catch {
            throw BookMetadataServiceError.decodingError
        }
        
        // 結果検証とベストマッチ選択
        guard let items = volumesResponse.items, !items.isEmpty else {
            throw BookMetadataServiceError.bookNotFound
        }
        
        let bestMatch = selectBestMatch(items: items, targetISBN: normalizedISBN)
        return mapToBookMetadata(volume: bestMatch)
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
    
    /// Google Books APIのレスポンスをBookMetadataにマッピングする
    /// - Parameter volume: Google Books APIのボリューム
    /// - Returns: BookMetadata
    private func mapToBookMetadata(volume: Volume) -> BookMetadata {
        let volumeInfo = volume.volumeInfo
        
        // サムネイルURLの処理（httpをhttpsに変換）
        let thumbnailURL: URL? = {
            let thumbnailString =
                volumeInfo.imageLinks?.thumbnail ?? volumeInfo.imageLinks?.smallThumbnail
            guard let urlString = thumbnailString else { return nil }
            let httpsString = urlString.replacingOccurrences(of: "http://", with: "https://")
            return URL(string: httpsString)
        }()

        // ISBN情報の抽出
        let isbn13 = volumeInfo.industryIdentifiers?.first { $0.type == "ISBN_13" }?.identifier
        let isbn10 = volumeInfo.industryIdentifiers?.first { $0.type == "ISBN_10" }?.identifier
        
        return BookMetadata(
            title: volumeInfo.title ?? "（タイトル未取得）",
            authors: volumeInfo.authors ?? [],
            publisher: volumeInfo.publisher,
            publishedDate: volumeInfo.publishedDate,
            description: volumeInfo.description,
            pageCount: volumeInfo.pageCount,
            categories: volumeInfo.categories ?? [],
            thumbnailURL: thumbnailURL,
            infoLink: volumeInfo.infoLink,
            isbn13: isbn13,
            isbn10: isbn10
        )
    }
}

// MARK: - Google Books API Response Models

/// Google Books API レスポンスルート
struct VolumesResponse: Decodable {
    let items: [Volume]?
}

/// 書籍ボリューム
struct Volume: Decodable {
    let volumeInfo: VolumeInfo
}

/// 書籍詳細情報
struct VolumeInfo: Decodable {
    let title: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
    let infoLink: URL?
}

/// 画像リンク
struct ImageLinks: Decodable {
    let smallThumbnail: String?
    let thumbnail: String?
}

/// 業界識別子（ISBN等）
struct IndustryIdentifier: Decodable {
    let type: String
    let identifier: String
}
