import Foundation
import Observation
import PictureBookLendingDomain

/// クラス（組）管理に関するエラー
public enum ClassGroupModelError: Error, Equatable, LocalizedError {
    /// 指定されたクラスが見つからない場合のエラー
    case classGroupNotFound
    /// クラス登録に失敗した場合のエラー
    case registrationFailed
    /// クラス更新に失敗した場合のエラー
    case updateFailed
    /// クラス削除に失敗した場合のエラー
    case deletionFailed
    
    public var errorDescription: String? {
        switch self {
        case .classGroupNotFound:
            return "指定されたクラスが見つかりません"
        case .registrationFailed:
            return "クラスの登録に失敗しました"
        case .updateFailed:
            return "クラス情報の更新に失敗しました"
        case .deletionFailed:
            return "クラスの削除に失敗しました"
        }
    }
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
@MainActor
public class ClassGroupModel {
    
    /// クラスリポジトリ
    private let repository: ClassGroupRepositoryProtocol
    
    /// キャッシュ用のクラスリスト
    public private(set) var classGroups: [ClassGroup] = []
    
    /// イニシャライザ
    ///
    /// - Parameter repository: クラスリポジトリ
    public init(repository: ClassGroupRepositoryProtocol) {
        self.repository = repository
        
        // 初期データのロード
        do {
            self.classGroups = try repository.fetchAll().sorted(by: { $0.ageGroup < $1.ageGroup })
        } catch {
            print("初期データのロードに失敗しました: \(error)")
            self.classGroups = []
        }
    }
    
    /// クラスを登録する
    ///
    /// 新しいクラスを管理リストに追加します。
    ///
    /// - Parameter classGroup: 登録するクラスの情報
    /// - Throws: 登録に失敗した場合は `ClassGroupModelError.registrationFailed` を投げます
    public func registerClassGroup(_ classGroup: ClassGroup) throws {
        do {
            try repository.save(classGroup)
            
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
    public func findClassGroupById(_ id: UUID) -> ClassGroup? {
        // キャッシュから検索
        if let cachedClassGroup = classGroups.first(where: { $0.id == id }) {
            return cachedClassGroup
        }
        
        // リポジトリから検索
        do {
            return try repository.fetch(by: id)
        } catch {
            print("クラスの検索に失敗しました: \(error)")
            return nil
        }
    }
    
    /// クラス情報を更新する
    ///
    /// 指定されたクラスの情報を更新します。
    ///
    /// - Parameter classGroup: 更新するクラス情報（IDで既存のクラスを特定）
    /// - Throws: 更新に失敗した場合は `ClassGroupModelError` を投げます
    public func updateClassGroup(_ classGroup: ClassGroup) throws {
        do {
            try repository.save(classGroup)
            
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
    public func deleteClassGroup(_ id: UUID) throws {
        do {
            try repository.delete(by: id)
            
            // キャッシュからも削除
            classGroups.removeAll(where: { $0.id == id })
        } catch {
            throw ClassGroupModelError.deletionFailed
        }
    }
    
    /// クラスリストを最新の状態に更新する
    ///
    /// リポジトリから最新のデータを取得して内部キャッシュを更新します。
    public func refreshClassGroups() {
        do {
            classGroups = try repository.fetchAll().sorted(by: { $0.ageGroup < $1.ageGroup })
        } catch {
            print("クラスリストの更新に失敗しました: \(error)")
        }
    }
    
    /// 全てのクラスグループを削除する
    ///
    /// 全クラスグループデータを削除します。端末初期化時に使用されます。
    ///
    /// - Returns: 削除されたクラスグループの数
    /// - Throws: 削除に失敗した場合は `ClassGroupModelError` を投げます
    public func deleteAllClassGroups() throws -> Int {
        do {
            let currentClassGroups = classGroups
            
            // 全てのクラスグループを削除
            for classGroup in currentClassGroups {
                try repository.delete(by: classGroup.id)
            }
            
            // キャッシュもクリア
            classGroups.removeAll()
            
            return currentClassGroups.count
        } catch {
            throw ClassGroupModelError.deletionFailed
        }
    }
    
    /// 次のクラスグループを取得する
    ///
    /// 現在のクラスグループから進級先のクラスグループを作成します。
    /// 上の年齢区分の対応するクラス名を流用します。
    ///
    /// - Parameter current: 現在のクラスグループ
    /// - Returns: 進級先のクラスグループ
    private func nextClassGroup(current: ClassGroup) -> ClassGroup? {
        // その他の場合は年度だけ更新
        if current.ageGroup == .other {
            return ClassGroup(
                id: current.id,
                name: current.name,
                ageGroup: current.ageGroup,
                year: current.year + 1
            )
        }
        // 進級可能な場合は翌年度の組を変更
        if let nextAgeGroup = current.ageGroup.nextAgeGroup(),
            let nextClassGroup = classGroups.first(where: { $0.ageGroup == nextAgeGroup })
        {
            return ClassGroup(
                id: current.id,
                name: nextClassGroup.name,
                ageGroup: nextClassGroup.ageGroup,
                year: current.year + 1
            )
        }
        
        return nil
    }
    
    /// 進級処理を実行する
    ///
    /// 全クラスの年齢区分を次の年齢に進級させ、年度を更新します。
    /// 5歳児クラスは卒業として削除されます。
    ///
    /// - Returns: 削除されたクラスグループの配列
    /// - Throws: 進級処理に失敗した場合は `ClassGroupModelError` を投げます
    public func promoteToNextYear() throws -> [ClassGroup] {
        do {
            let currentClassGroups = classGroups
            var updatedClassGroups: [ClassGroup] = []
            var deletedClassGroups: [ClassGroup] = []
            
            // 最小クラスを作成
            let firstClassGroup = currentClassGroups.filter { $0.ageGroup != .other }
                .sorted { $0.ageGroup < $1.ageGroup }
                .first
            if let firstClassGroup {
                let updatedFirstClassGroup = ClassGroup(
                    name: firstClassGroup.name,
                    ageGroup: firstClassGroup.ageGroup,
                    year: firstClassGroup.year + 1)
                try repository.save(updatedFirstClassGroup)
                updatedClassGroups.append(updatedFirstClassGroup)
            }
            
            // 各クラスグループを進級処理
            for classGroup in currentClassGroups {
                if let nextClassGroupInstance = nextClassGroup(current: classGroup) {
                    // 進級可能な場合は進級先の組へ更新
                    try repository.save(nextClassGroupInstance)
                    updatedClassGroups.append(nextClassGroupInstance)
                } else {
                    // 進級不可（5歳児など）の場合は削除対象として記録
                    deletedClassGroups.append(classGroup)
                    try repository.delete(by: classGroup.id)
                }
            }
            // キャッシュを更新
            classGroups = updatedClassGroups.sorted(by: { $0.ageGroup < $1.ageGroup })
            
            // 削除されたクラスグループを返却
            return deletedClassGroups
            
        } catch {
            throw ClassGroupModelError.updateFailed
        }
    }
}
