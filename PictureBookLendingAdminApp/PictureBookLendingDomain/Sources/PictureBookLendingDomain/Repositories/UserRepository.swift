import Foundation

/// 利用者リポジトリプロトコル
///
/// 利用者の永続化を担当するリポジトリのインターフェース
public protocol UserRepository {
    /**
     * 利用者を保存する
     *
     * - Parameter user: 保存する利用者
     * - Returns: 保存された利用者
     * - Throws: 保存に失敗した場合はエラーを投げる
     */
    func save(_ user: User) throws -> User
    
    /**
     * 全ての利用者を取得する
     *
     * - Returns: 全ての利用者のリスト
     * - Throws: 取得に失敗した場合はエラーを投げる
     */
    func fetchAll() throws -> [User]
    
    /**
     * IDで利用者を検索する
     *
     * - Parameter id: 検索する利用者のID
     * - Returns: 見つかった利用者（見つからない場合はnil）
     * - Throws: 検索に失敗した場合はエラーを投げる
     */
    func findById(_ id: UUID) throws -> User?
    
    /**
     * 利用者を更新する
     *
     * - Parameter user: 更新する利用者
     * - Returns: 更新された利用者
     * - Throws: 更新に失敗した場合はエラーを投げる
     */
    func update(_ user: User) throws -> User
    
    /**
     * 利用者を削除する
     *
     * - Parameter id: 削除する利用者のID
     * - Returns: 削除に成功したかどうか
     * - Throws: 削除に失敗した場合はエラーを投げる
     */
    func delete(_ id: UUID) throws -> Bool
}
