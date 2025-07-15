import Foundation
import PictureBookLendingDomain
import SwiftData

/// SwiftData用クラス（組）リポジトリ実装
///
/// SwiftDataを使用してクラス（組）の永続化を担当するリポジトリ
public class SwiftDataClassGroupRepository: ClassGroupRepositoryProtocol {
    private let modelContext: ModelContext
    
    /// イニシャライザ
    ///
    /// - Parameter modelContext: SwiftData用のモデルコンテキスト
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// すべてのクラスを取得する
    ///
    /// - Returns: すべてのクラスの配列
    /// - Throws: 取得に失敗した場合はエラーを投げる
    public func fetchAll() throws -> [ClassGroup] {
        do {
            let descriptor = FetchDescriptor<SwiftDataClassGroup>()
            let swiftDataClassGroups = try modelContext.fetch(descriptor)
            
            // SwiftDataモデルからドメインモデルに変換
            return swiftDataClassGroups.map { swiftDataClassGroup in
                ClassGroup(
                    id: swiftDataClassGroup.id,
                    name: swiftDataClassGroup.name,
                    ageGroup: swiftDataClassGroup.ageGroup,
                    year: swiftDataClassGroup.year
                )
            }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /// 指定されたIDのクラスを取得する
    ///
    /// - Parameter id: 検索するクラスのID
    /// - Returns: 見つかったクラス（見つからない場合はnil）
    /// - Throws: 検索に失敗した場合はエラーを投げる
    public func fetch(by id: UUID) throws -> ClassGroup? {
        do {
            let predicate = #Predicate<SwiftDataClassGroup> { $0.id == id }
            let descriptor = FetchDescriptor<SwiftDataClassGroup>(predicate: predicate)
            
            let swiftDataClassGroups = try modelContext.fetch(descriptor)
            guard let swiftDataClassGroup = swiftDataClassGroups.first else {
                return nil
            }
            
            return ClassGroup(
                id: swiftDataClassGroup.id,
                name: swiftDataClassGroup.name,
                ageGroup: swiftDataClassGroup.ageGroup,
                year: swiftDataClassGroup.year
            )
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /// クラスを保存する（新規作成または更新）
    ///
    /// - Parameter classGroup: 保存するクラス
    /// - Throws: 保存に失敗した場合はエラーを投げる
    public func save(_ classGroup: ClassGroup) throws {
        do {
            // 既存のクラスを検索
            let predicate = #Predicate<SwiftDataClassGroup> { $0.id == classGroup.id }
            let descriptor = FetchDescriptor<SwiftDataClassGroup>(predicate: predicate)
            let existingClassGroups = try modelContext.fetch(descriptor)
            
            if let existingClassGroup = existingClassGroups.first {
                // 更新
                existingClassGroup.name = classGroup.name
                existingClassGroup.ageGroup = classGroup.ageGroup
                existingClassGroup.year = classGroup.year
            } else {
                // 新規作成
                let swiftDataClassGroup = SwiftDataClassGroup(
                    id: classGroup.id,
                    name: classGroup.name,
                    ageGroup: classGroup.ageGroup,
                    year: classGroup.year
                )
                modelContext.insert(swiftDataClassGroup)
            }
            
            try modelContext.save()
        } catch {
            throw RepositoryError.saveFailed
        }
    }
    
    /// 指定されたIDのクラスを削除する
    ///
    /// - Parameter id: 削除するクラスのID
    /// - Throws: 削除に失敗した場合はエラーを投げる
    public func delete(by id: UUID) throws {
        do {
            let predicate = #Predicate<SwiftDataClassGroup> { $0.id == id }
            let descriptor = FetchDescriptor<SwiftDataClassGroup>(predicate: predicate)
            
            let swiftDataClassGroups = try modelContext.fetch(descriptor)
            guard let swiftDataClassGroup = swiftDataClassGroups.first else {
                throw RepositoryError.notFound
            }
            
            modelContext.delete(swiftDataClassGroup)
            try modelContext.save()
        } catch RepositoryError.notFound {
            throw RepositoryError.notFound
        } catch {
            throw RepositoryError.deleteFailed
        }
    }
    
}

/// SwiftData用のクラス（組）モデル
///
/// SwiftDataで永続化するためのクラス（組）モデル
@Model
final public class SwiftDataClassGroup {
    public var id: UUID
    public var name: String
    public var ageGroup: Int
    public var year: Int
    
    public init(id: UUID, name: String, ageGroup: Int, year: Int) {
        self.id = id
        self.name = name
        self.ageGroup = ageGroup
        self.year = year
    }
}
