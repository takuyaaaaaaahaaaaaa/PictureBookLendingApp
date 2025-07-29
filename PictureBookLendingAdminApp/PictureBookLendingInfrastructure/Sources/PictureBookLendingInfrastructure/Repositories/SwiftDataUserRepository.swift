import Foundation
import PictureBookLendingDomain
import SwiftData

/// SwiftData用利用者リポジトリ実装
///
/// SwiftDataを使用して利用者の永続化を担当するリポジトリ
public class SwiftDataUserRepository: UserRepositoryProtocol {
    private let modelContext: ModelContext
    
    ///
    /// イニシャライザ
    /// - Parameter modelContext: SwiftData用のモデルコンテキスト
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    ///
    /// 利用者を保存する
    /// - Parameter user: 保存する利用者
    /// - Returns: 保存された利用者
    /// - Throws: 保存に失敗した場合はエラーを投げる
    
    public func save(_ user: User) throws -> User {
        // SwiftDataでは、オブジェクトをモデルコンテキストに挿入してSwiftDataモデルに変換
        let swiftDataUser = SwiftDataUser(
            id: user.id,
            name: user.name,
            classGroupId: user.classGroupId
        )
        
        modelContext.insert(swiftDataUser)
        
        do {
            try modelContext.save()
            return user
        } catch {
            throw RepositoryError.saveFailed
        }
    }
    
    ///
    /// 全ての利用者を取得する
    /// - Returns: 全ての利用者のリスト
    /// - Throws: 取得に失敗した場合はエラーを投げる
    
    public func fetchAll() throws -> [User] {
        do {
            let descriptor = FetchDescriptor<SwiftDataUser>()
            let swiftDataUsers = try modelContext.fetch(descriptor)
            
            // SwiftDataモデルからドメインモデルに変換
            return swiftDataUsers.map { swiftDataUser in
                User(
                    id: swiftDataUser.id,
                    name: swiftDataUser.name,
                    classGroupId: swiftDataUser.classGroupId
                )
            }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    ///
    /// IDで利用者を検索する
    /// - Parameter id: 検索する利用者のID
    /// - Returns: 見つかった利用者（見つからない場合はnil）
    /// - Throws: 検索に失敗した場合はエラーを投げる
    
    public func findById(_ id: UUID) throws -> User? {
        do {
            let predicate = #Predicate<SwiftDataUser> { $0.id == id }
            let descriptor = FetchDescriptor<SwiftDataUser>(predicate: predicate)
            
            let swiftDataUsers = try modelContext.fetch(descriptor)
            guard let swiftDataUser = swiftDataUsers.first else {
                return nil
            }
            
            return User(
                id: swiftDataUser.id,
                name: swiftDataUser.name,
                classGroupId: swiftDataUser.classGroupId
            )
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    ///
    /// 利用者を更新する
    /// - Parameter user: 更新する利用者
    /// - Returns: 更新された利用者
    /// - Throws: 更新に失敗した場合はエラーを投げる
    
    public func update(_ user: User) throws -> User {
        do {
            let predicate = #Predicate<SwiftDataUser> { $0.id == user.id }
            let descriptor = FetchDescriptor<SwiftDataUser>(predicate: predicate)
            
            let swiftDataUsers = try modelContext.fetch(descriptor)
            guard let swiftDataUser = swiftDataUsers.first else {
                throw RepositoryError.notFound
            }
            
            // プロパティを更新
            swiftDataUser.name = user.name
            swiftDataUser.classGroupId = user.classGroupId
            
            try modelContext.save()
            
            return user
        } catch RepositoryError.notFound {
            throw RepositoryError.notFound
        } catch {
            throw RepositoryError.updateFailed
        }
    }
    
    ///
    /// 利用者を削除する
    /// - Parameter id: 削除する利用者のID
    /// - Returns: 削除に成功したかどうか
    /// - Throws: 削除に失敗した場合はエラーを投げる
    
    public func delete(_ id: UUID) throws -> Bool {
        do {
            let predicate = #Predicate<SwiftDataUser> { $0.id == id }
            let descriptor = FetchDescriptor<SwiftDataUser>(predicate: predicate)
            
            let swiftDataUsers = try modelContext.fetch(descriptor)
            guard let swiftDataUser = swiftDataUsers.first else {
                throw RepositoryError.notFound
            }
            
            modelContext.delete(swiftDataUser)
            try modelContext.save()
            
            return true
        } catch RepositoryError.notFound {
            throw RepositoryError.notFound
        } catch {
            throw RepositoryError.deleteFailed
        }
    }
}
