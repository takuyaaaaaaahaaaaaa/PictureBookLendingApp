import Foundation
import PictureBookLendingDomain

/// BookMetadataServiceProtocolの実装
/// Google Books APIを使用して書籍メタデータを取得します
public struct BookMetadataServiceLive: BookMetadataServiceProtocol {
    
    /// Google Books APIクライアント
    private let apiClient: GoogleBooksAPIClient
    
    /// 初期化
    /// - Parameter apiClient: Google Books APIクライアント
    public init(apiClient: GoogleBooksAPIClient = GoogleBooksAPIClient()) {
        self.apiClient = apiClient
    }
    
    /// ISBNから書籍メタデータを取得する
    /// - Parameter isbn: ISBN-13またはISBN-10
    /// - Returns: 取得した書誌メタデータ
    /// - Throws: BookMetadataServiceError
    public func fetchMetadata(for isbn: String) async throws -> BookMetadata {
        return try await apiClient.fetchMetadata(for: isbn)
    }
}
