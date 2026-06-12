import Foundation

/// 書籍メタデータゲートウェイのエラー
///
/// 外部APIから書籍メタデータを取得する際に発生する可能性があるエラーを定義します。
public enum BookMetadataGatewayError: Error, Equatable {
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

// MARK: - LocalizedError

extension BookMetadataGatewayError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidISBN:
            return "無効なISBN形式です"
        case .bookNotFound:
            return "書籍が見つかりませんでした"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .decodingError:
            return "APIレスポンスの解析に失敗しました"
        case .httpError(let statusCode):
            return "HTTPエラーが発生しました（ステータスコード: \(statusCode)）"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}
