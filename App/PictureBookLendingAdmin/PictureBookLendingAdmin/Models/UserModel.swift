import Foundation
import PictureBookLendingCore

/**
 * 利用者管理に関するエラー
 */
enum UserModelError: Error, Equatable {
    /// 指定された利用者が見つからない場合のエラー
    case userNotFound
    /// 利用者登録に失敗した場合のエラー
    case registrationFailed
    /// 利用者情報更新に失敗した場合のエラー
    case updateFailed
}

/**
 * 利用者管理モデル
 *
 * 利用者のCRUD操作を管理するモデルクラスです。
 * - 利用者の登録
 * - 利用者の一覧取得
 * - 利用者のID検索
 * - 利用者情報の更新
 * - 利用者の削除
 * などの機能を提供します。
 */
class UserModel {
    
    /// 管理している利用者のリスト
    private(set) var users: [User] = []
    
    /**
     * 利用者を登録する
     * 
     * 新しい利用者を管理リストに追加します。
     *
     * - Parameter user: 登録する利用者の情報
     * - Returns: 登録された利用者（IDが割り当てられます）
     * - Throws: 登録に失敗した場合は `UserModelError.registrationFailed` を投げます
     */
    func registerUser(_ user: User) throws -> User {
        // 重複IDをチェック
        if let _ = users.first(where: { $0.id == user.id }) {
            throw UserModelError.registrationFailed
        }
        
        // 追加
        users.append(user)
        return user
    }
    
    /**
     * 全ての利用者を取得する
     *
     * 管理中の全利用者リストを返します。
     *
     * - Returns: 全ての利用者の配列
     */
    func getAllUsers() -> [User] {
        return users
    }
    
    /**
     * 指定IDの利用者を検索する
     *
     * IDを指定して利用者を検索します。
     *
     * - Parameter id: 検索する利用者のID
     * - Returns: 見つかった利用者（見つからない場合はnil）
     */
    func findUserById(_ id: UUID) -> User? {
        return users.first { $0.id == id }
    }
    
    /**
     * 利用者情報を更新する
     *
     * 指定された利用者の情報を更新します。
     *
     * - Parameter user: 更新する利用者情報（IDで既存の利用者を特定）
     * - Returns: 更新された利用者
     * - Throws: 更新に失敗した場合は `UserModelError` を投げます
     */
    func updateUser(_ user: User) throws -> User {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            throw UserModelError.userNotFound
        }
        
        users[index] = user
        return user
    }
    
    /**
     * 利用者を削除する
     *
     * 指定されたIDの利用者を削除します。
     *
     * - Parameter id: 削除する利用者のID
     * - Returns: 削除に成功したかどうか
     * - Throws: 削除対象が見つからない場合は `UserModelError.userNotFound` を投げます
     */
    func deleteUser(_ id: UUID) throws -> Bool {
        guard let index = users.firstIndex(where: { $0.id == id }) else {
            throw UserModelError.userNotFound
        }
        
        users.remove(at: index)
        return true
    }
}