import Foundation

/**
 * リポジトリ操作に関するエラー
 *
 * データの永続化や取得に関する各種エラーを定義します
 */
public enum RepositoryError: Error, Equatable {
    /// データが見つからない場合のエラー
    case notFound
    /// データの保存に失敗した場合のエラー
    case saveFailed
    /// データの取得に失敗した場合のエラー
    case fetchFailed
    /// データの更新に失敗した場合のエラー
    case updateFailed
    /// データの削除に失敗した場合のエラー
    case deleteFailed
}