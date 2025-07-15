import Foundation

/// クラス（組）データの永続化を管理するリポジトリのプロトコル
public protocol ClassGroupRepositoryProtocol {
    /// すべてのクラスを取得する
    func fetchAll() async throws -> [ClassGroup]
    
    /// 指定されたIDのクラスを取得する
    func fetch(by id: UUID) async throws -> ClassGroup?
    
    /// クラスを保存する（新規作成または更新）
    func save(_ classGroup: ClassGroup) async throws
    
    /// 複数のクラスを一括保存する
    func saveBatch(_ classGroups: [ClassGroup]) async throws
    
    /// 指定されたIDのクラスを削除する
    func delete(by id: UUID) async throws
    
    /// 指定された年度のクラスを取得する
    func fetchByYear(_ year: Int) async throws -> [ClassGroup]
    
    /// 指定された年齢グループのクラスを取得する
    func fetchByAgeGroup(_ ageGroup: Int) async throws -> [ClassGroup]
}
