import Foundation

/// 書誌情報取得サービスのエラー
public enum BookMetadataServiceError: Error, Equatable {
    /// 無効なISBN形式
    case invalidISBN
    /// 書籍が見つからない
    case bookNotFound
    /// ネットワークエラー
    case networkError
    /// APIレスポンスの解析エラー
    case decodingError
    /// HTTPステータスエラー
    case httpError(statusCode: Int)
    /// その他のエラー
    case unknown
}

/// 外部APIから取得した書誌メタデータ
public struct BookMetadata: Codable, Hashable, Sendable {
    /// タイトル
    public let title: String
    /// 著者リスト
    public let authors: [String]
    /// 出版社
    public let publisher: String?
    /// 出版日
    public let publishedDate: String?
    /// 説明・あらすじ
    public let description: String?
    /// ページ数
    public let pageCount: Int?
    /// カテゴリ・ジャンル
    public let categories: [String]
    /// サムネイル画像URL
    public let thumbnailURL: URL?
    /// 情報リンクURL
    public let infoLink: URL?
    /// ISBN-13
    public let isbn13: String?
    /// ISBN-10
    public let isbn10: String?
    
    public init(
        title: String,
        authors: [String],
        publisher: String? = nil,
        publishedDate: String? = nil,
        description: String? = nil,
        pageCount: Int? = nil,
        categories: [String] = [],
        thumbnailURL: URL? = nil,
        infoLink: URL? = nil,
        isbn13: String? = nil,
        isbn10: String? = nil
    ) {
        self.title = title
        self.authors = authors
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.description = description
        self.pageCount = pageCount
        self.categories = categories
        self.thumbnailURL = thumbnailURL
        self.infoLink = infoLink
        self.isbn13 = isbn13
        self.isbn10 = isbn10
    }
}

/// 書誌情報取得サービスのプロトコル
/// 外部API（Google Books API等）から書籍の詳細情報を取得する機能を抽象化します
public protocol BookMetadataServiceProtocol {
    /// ISBNから書誌情報を取得する
    /// - Parameter isbn: ISBN-13またはISBN-10
    /// - Returns: 取得した書誌メタデータ
    /// - Throws: BookMetadataServiceError
    func fetchMetadata(for isbn: String) async throws -> BookMetadata
}
