import Foundation
import Observation
import PictureBookLendingDomain

/// クラス（組）管理に関するエラー
public enum ClassGroupModelError: Error, Equatable {
    /// 指定されたクラスが見つからない場合のエラー
    case classGroupNotFound
    /// クラス登録に失敗した場合のエラー
    case registrationFailed
    /// クラス更新に失敗した場合のエラー
    case updateFailed
    /// クラス削除に失敗した場合のエラー
    case deletionFailed
}

/// クラス（組）管理モデル
///
/// クラス（組）のCRUD操作を管理するモデルクラスです。
/// - クラスの登録
/// - クラスの一覧取得
/// - クラスのID検索
/// - クラス情報の更新
/// - クラスの削除
/// - 年度別、年齢別のクラス検索
/// などの機能を提供します。
@Observable
public class ClassGroupModel {
    
    /// クラスリポジトリ
    private let repository: ClassGroupRepository
    
    /// キャッシュ用のクラスリスト
    public private(set) var classGroups: [ClassGroup] = []
    
    /// イニシャライザ
    ///
    /// - Parameter repository: クラスリポジトリ
    public init(repository: ClassGroupRepository) {
        self.repository = repository
    }
    
    /// すべてのクラスをロードする
    ///
    /// リポジトリからすべてのクラス情報を取得してキャッシュに保存します。
    public func loadAllClassGroups() async throws {
        classGroups = try await repository.fetchAll()
    }
    
    /// クラスを登録する
    ///
    /// 新しいクラスを管理リストに追加します。
    ///
    /// - Parameter classGroup: 登録するクラスの情報
    /// - Throws: 登録に失敗した場合は `ClassGroupModelError.registrationFailed` を投げます
    public func registerClassGroup(_ classGroup: ClassGroup) async throws {
        do {
            try await repository.save(classGroup)
            
            // キャッシュに追加
            if !classGroups.contains(where: { $0.id == classGroup.id }) {
                classGroups.append(classGroup)
            }
        } catch {
            throw ClassGroupModelError.registrationFailed
        }
    }
    
    /// すべてのクラスを取得する
    ///
    /// 管理中の全クラスリストを返します。
    ///
    /// - Returns: すべてのクラスの配列
    public func getAllClassGroups() -> [ClassGroup] {
        return classGroups
    }
    
    /// 指定IDのクラスを検索する
    ///
    /// IDを指定してクラスを検索します。
    ///
    /// - Parameter id: 検索するクラスのID
    /// - Returns: 見つかったクラス（見つからない場合はnil）
    public func findClassGroupById(_ id: UUID) async -> ClassGroup? {
        // キャッシュから検索
        if let cachedClassGroup = classGroups.first(where: { $0.id == id }) {
            return cachedClassGroup
        }
        
        // リポジトリから検索
        do {
            return try await repository.fetch(by: id)
        } catch {
            print("クラスの検索に失敗しました: \(error)")
            return nil
        }
    }
    
    /// 指定された年度のクラスを取得する
    ///
    /// - Parameter year: 年度
    /// - Returns: 指定年度のクラス配列
    public func getClassGroupsByYear(_ year: Int) async throws -> [ClassGroup] {
        return try await repository.fetchByYear(year)
    }
    
    /// 指定された年齢グループのクラスを取得する
    ///
    /// - Parameter ageGroup: 年齢グループ
    /// - Returns: 指定年齢グループのクラス配列
    public func getClassGroupsByAgeGroup(_ ageGroup: Int) async throws -> [ClassGroup] {
        return try await repository.fetchByAgeGroup(ageGroup)
    }
    
    /// クラス情報を更新する
    ///
    /// 指定されたクラスの情報を更新します。
    ///
    /// - Parameter classGroup: 更新するクラス情報（IDで既存のクラスを特定）
    /// - Throws: 更新に失敗した場合は `ClassGroupModelError` を投げます
    public func updateClassGroup(_ classGroup: ClassGroup) async throws {
        do {
            try await repository.save(classGroup)
            
            // キャッシュも更新
            if let index = classGroups.firstIndex(where: { $0.id == classGroup.id }) {
                classGroups[index] = classGroup
            } else {
                // キャッシュになければ追加
                classGroups.append(classGroup)
            }
        } catch {
            throw ClassGroupModelError.updateFailed
        }
    }
    
    /// クラスを削除する
    ///
    /// 指定されたIDのクラスを削除します。
    ///
    /// - Parameter id: 削除するクラスのID
    /// - Throws: 削除に失敗した場合は `ClassGroupModelError` を投げます
    public func deleteClassGroup(_ id: UUID) async throws {
        do {
            try await repository.delete(by: id)
            
            // キャッシュからも削除
            classGroups.removeAll(where: { $0.id == id })
        } catch {
            throw ClassGroupModelError.deletionFailed
        }
    }
    
    /// 複数のクラスを一括保存する
    ///
    /// - Parameter classGroups: 保存するクラスの配列
    /// - Throws: 保存に失敗した場合は `ClassGroupModelError.registrationFailed` を投げます
    public func saveBatchClassGroups(_ classGroups: [ClassGroup]) async throws {
        do {
            try await repository.saveBatch(classGroups)
            
            // キャッシュを更新
            for classGroup in classGroups {
                if let index = self.classGroups.firstIndex(where: { $0.id == classGroup.id }) {
                    self.classGroups[index] = classGroup
                } else {
                    self.classGroups.append(classGroup)
                }
            }
        } catch {
            throw ClassGroupModelError.registrationFailed
        }
    }
    
    /// クラスリストを最新の状態に更新する
    ///
    /// リポジトリから最新のデータを取得して内部キャッシュを更新します。
    public func refreshClassGroups() async {
        do {
            classGroups = try await repository.fetchAll()
        } catch {
            print("クラスリストの更新に失敗しました: \(error)")
        }
    }
}
