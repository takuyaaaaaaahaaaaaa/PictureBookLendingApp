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
}
