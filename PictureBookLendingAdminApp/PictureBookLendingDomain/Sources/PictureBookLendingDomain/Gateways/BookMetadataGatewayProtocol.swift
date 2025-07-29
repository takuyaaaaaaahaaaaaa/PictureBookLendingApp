import Foundation

/// 書籍メタデータゲートウェイプロトコル
///
/// 外部APIから取得した書籍メタデータをドメインモデル（Book）に変換して提供する
/// ゲートウェイの責務を定義します。
///
/// このプロトコルは腐敗防止層（Anti-Corruption Layer）として機能し、
/// 外部システムの変更からドメインモデルを保護します。
public protocol BookMetadataGatewayProtocol {
    
    /// 指定されたISBNで書籍をドメインモデルとして取得する
    ///
    /// - Parameter isbn: 取得する書籍のISBN-13またはISBN-10
    /// - Returns: ドメインモデルとしてのBook
    /// - Throws: BookMetadataGatewayError
    func getBook(by isbn: String) async throws -> Book
}
