import Foundation

/// 書籍検索ゲートウェイプロトコル
///
/// 外部APIから書籍情報を検索・取得し、ドメインモデル（Book）に変換して提供する
/// ゲートウェイの責務を定義します。
///
/// このプロトコルは腐敗防止層（Anti-Corruption Layer）として機能し、
/// 外部システムの変更からドメインモデルを保護します。
public protocol BookSearchGatewayProtocol: Sendable {
    
    /// 指定されたISBNで書籍を検索する
    ///
    /// - Parameter isbn: 検索する書籍のISBN-13またはISBN-10
    /// - Returns: ドメインモデルとしてのBook
    /// - Throws: BookMetadataGatewayError
    func searchBook(by isbn: String) async throws -> Book
    
    /// タイトルと著者名で書籍を検索する
    ///
    /// - Parameters:
    ///   - title: 書籍のタイトル
    ///   - author: 著者名（オプション）
    ///   - maxResults: 最大取得件数（デフォルトは20）
    /// - Returns: 検索結果の書籍リスト
    /// - Throws: BookMetadataGatewayError
    func searchBooks(title: String, author: String?, maxResults: Int) async throws -> [Book]
}
