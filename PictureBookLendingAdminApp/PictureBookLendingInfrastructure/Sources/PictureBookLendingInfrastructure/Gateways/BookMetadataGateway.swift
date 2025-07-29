import Foundation
import PictureBookLendingDomain

/// 書籍メタデータゲートウェイの実装
/// Google Books APIを使用して書籍情報をドメインモデルとして取得します
public struct BookMetadataGateway: BookMetadataGatewayProtocol {
    
    /// Google Books APIクライアント
    private let apiClient: GoogleBooksAPIClient
    
    /// 初期化
    /// - Parameter apiClient: Google Books APIクライアント
    public init(apiClient: GoogleBooksAPIClient = GoogleBooksAPIClient()) {
        self.apiClient = apiClient
    }
    
    /// 指定されたISBNで書籍をドメインモデルとして取得する
    /// - Parameter isbn: 取得する書籍のISBN-13またはISBN-10
    /// - Returns: ドメインモデルとしてのBook
    /// - Throws: BookMetadataGatewayError
    public func getBook(by isbn: String) async throws -> Book {
        return try await apiClient.fetchBook(for: isbn)
    }
}
