import Foundation
import Observation
import PictureBookLendingDomain

/// 利用者管理に関するエラー
public enum UserModelError: Error, Equatable {
    /// 指定された利用者が見つからない場合のエラー
    case userNotFound
    /// 利用者登録に失敗した場合のエラー
    case registrationFailed
    /// 利用者情報更新に失敗した場合のエラー
    case updateFailed
}

/// 利用者管理モデル
///
/// 利用者のCRUD操作を管理するモデルクラスです。
/// - 利用者の登録
/// - 利用者の一覧取得
/// - 利用者のID検索
/// - 利用者情報の更新
/// - 利用者の削除
/// などの機能を提供します。
@Observable
public class UserModel {
    
    /// 利用者リポジトリ
    private let repository: UserRepository
    
    /// キャッシュ用の利用者リスト
    public private(set) var users: [User] = []
    
    /**
     * イニシャライザ
     *
     * - Parameter repository: 利用者リポジトリ
     */
    public init(repository: UserRepository) {
        self.repository = repository
        
        // 初期データのロード
        do {
            self.users = try repository.fetchAll()
        } catch {
            print("初期データのロードに失敗しました: \(error)")
            self.users = []
        }
    }
    
    /**
     * 利用者を登録する
     *
     * 新しい利用者を管理リストに追加します。
     *
     * - Parameter user: 登録する利用者の情報
     * - Returns: 登録された利用者（IDが割り当てられます）
     * - Throws: 登録に失敗した場合は `UserModelError.registrationFailed` を投げます
     */
    public func registerUser(_ user: User) throws -> User {
        do {
            // リポジトリに保存
            let savedUser = try repository.save(user)
            
            // キャッシュに追加
            users.append(savedUser)
            
            return savedUser
        } catch {
            throw UserModelError.registrationFailed
        }
    }
    
    /**
     * 全ての利用者を取得する
     *
     * 管理中の全利用者リストを返します。
     *
     * - Returns: 全ての利用者の配列
     */
    public func getAllUsers() -> [User] {
        return users
    }
    
    /**
     * 利用者リストを最新の状態に更新する
     *
     * リポジトリから最新のデータを取得して内部キャッシュを更新します。
     */
    public func refreshUsers() {
        do {
            users = try repository.fetchAll()
        } catch {
            print("利用者リストの更新に失敗しました: \(error)")
        }
    }
    
    /**
     * 指定IDの利用者を検索する
     *
     * IDを指定して利用者を検索します。
     *
     * - Parameter id: 検索する利用者のID
     * - Returns: 見つかった利用者（見つからない場合はnil）
     */
    public func findUserById(_ id: UUID) -> User? {
        // キャッシュから検索
        if let cachedUser = users.first(where: { $0.id == id }) {
            return cachedUser
        }
        
        // リポジトリから検索
        do {
            return try repository.findById(id)
        } catch {
            print("利用者の検索に失敗しました: \(error)")
            return nil
        }
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
    public func updateUser(_ user: User) throws -> User {
        do {
            // リポジトリで更新
            let updatedUser = try repository.update(user)
            
            // キャッシュも更新
            if let index = users.firstIndex(where: { $0.id == user.id }) {
                users[index] = updatedUser
            } else {
                // キャッシュになければ追加
                users.append(updatedUser)
            }
            
            return updatedUser
        } catch RepositoryError.notFound {
            throw UserModelError.userNotFound
        } catch {
            throw UserModelError.updateFailed
        }
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
    public func deleteUser(_ id: UUID) throws -> Bool {
        do {
            // リポジトリから削除
            let result = try repository.delete(id)
            
            // キャッシュからも削除
            users.removeAll(where: { $0.id == id })
            
            return result
        } catch RepositoryError.notFound {
            throw UserModelError.userNotFound
        } catch {
            throw UserModelError.updateFailed
        }
    }
}
