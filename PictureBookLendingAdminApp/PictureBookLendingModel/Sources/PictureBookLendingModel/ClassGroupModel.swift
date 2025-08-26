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
            self.classGroups = try repository.fetchAll()
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
            classGroups = try repository.fetchAll()
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
        guard let nextAgeGroup = current.ageGroup.nextAgeGroup() else {
            return nil
        }
        
        // 年齢区分別にグループ化
        let groupsByAgeGroup = Dictionary(grouping: classGroups) { $0.ageGroup }
        
        // 現在の年齢区分内でのインデックスを取得
        let currentAgeGroupClasses = groupsByAgeGroup[current.ageGroup] ?? []
        let currentIndex = currentAgeGroupClasses.firstIndex(of: current) ?? 0
        
        // 次の年齢区分の対応するクラス名を取得
        let nextAgeGroupClasses = groupsByAgeGroup[nextAgeGroup] ?? []
        let newName = nextAgeGroupClasses.indices.contains(currentIndex) 
            ? nextAgeGroupClasses[currentIndex].name 
            : current.name
        
        return ClassGroup(
            id: current.id,
            name: newName,
            ageGroup: nextAgeGroup,
            year: current.year + 1
        )
    }
    
    /// 進級処理を実行する
    ///
    /// 全クラスの年齢区分を次の年齢に進級させ、年度を更新します。
    /// 5歳児クラスは卒業として削除されます。
    ///
    /// - Throws: 進級処理に失敗した場合は `ClassGroupModelError` を投げます
    public func promoteToNextYear() throws {
        do {
            let currentClassGroups = classGroups
            var updatedClassGroups: [ClassGroup] = []
            
            // 各クラスグループを処理
            for classGroup in currentClassGroups {
                let ageGroup = classGroup.ageGroup
                
                if case .other = ageGroup {
                    // その他（大人クラス）は年度のみ更新
                    let updatedClassGroup = ClassGroup(
                        id: classGroup.id,
                        name: classGroup.name,
                        ageGroup: classGroup.ageGroup,
                        year: classGroup.year + 1
                    )
                    
                    try repository.save(updatedClassGroup)
                    updatedClassGroups.append(updatedClassGroup)
                } else if let nextClassGroupInstance = nextClassGroup(current: classGroup) {
                    // 進級可能：nextClassGroupメソッドを使用
                    try repository.save(nextClassGroupInstance)
                    updatedClassGroups.append(nextClassGroupInstance)
                } else {
                    // 進級不可（5歳児など）は削除
                    try repository.delete(by: classGroup.id)
                }
            }
            
            // 0歳児のClassGroupを追加
            let zeroAgeClassGroups = currentClassGroups.filter { $0.ageGroup == .age(0) }
            for zeroAgeClassGroup in zeroAgeClassGroups {
                let newZeroAgeClassGroup = ClassGroup(
                    name: zeroAgeClassGroup.name,
                    ageGroup: .age(0),
                    year: zeroAgeClassGroup.year + 1
                )
                
                try repository.save(newZeroAgeClassGroup)
                updatedClassGroups.append(newZeroAgeClassGroup)
            }
            
            // ClassGroupをソート（年齢区分順、その後名前順）
            updatedClassGroups.sort { lhs, rhs in
                switch (lhs.ageGroup, rhs.ageGroup) {
                case let (.age(lhsAge), .age(rhsAge)):
                    return lhsAge < rhsAge
                case (.age(_), .other):
                    return true
                case (.other, .age(_)):
                    return false
                case (.other, .other):
                    return lhs.name < rhs.name
                }
            }
            
            // キャッシュを更新
            classGroups = updatedClassGroups
            
        } catch {
            throw ClassGroupModelError.updateFailed
        }
    }
}
