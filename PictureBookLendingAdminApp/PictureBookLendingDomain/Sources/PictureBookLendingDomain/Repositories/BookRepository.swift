import Foundation

/// 絵本リポジトリプロトコル
///
/// 絵本の永続化を担当するリポジトリのインターフェース
public protocol BookRepositoryProtocol: Sendable {
    /// 絵本を保存する
    ///
    /// - Parameter book: 保存する絵本
    /// - Returns: 保存された絵本
    /// - Throws: 保存に失敗した場合はエラーを投げる
    func save(_ book: Book) throws -> Book
    
    /// 全ての絵本を取得する
    ///
    /// - Returns: 全ての絵本のリスト
    /// - Throws: 取得に失敗した場合はエラーを投げる
    func fetchAll() throws -> [Book]
    
    /// IDで絵本を検索する
    ///
    /// - Parameter id: 検索する絵本のID
    /// - Returns: 見つかった絵本（見つからない場合はnil）
    /// - Throws: 検索に失敗した場合はエラーを投げる
    func findById(_ id: UUID) throws -> Book?
    
    /// 絵本を更新する
    ///
    /// - Parameter book: 更新する絵本
    /// - Returns: 更新された絵本
    /// - Throws: 更新に失敗した場合はエラーを投げる
    func update(_ book: Book) throws -> Book
    
    /// 絵本を削除する
    ///
    /// - Parameter id: 削除する絵本のID
    /// - Returns: 削除に成功したかどうか
    /// - Throws: 削除に失敗した場合はエラーを投げる
    func delete(_ id: UUID) throws -> Bool
}
