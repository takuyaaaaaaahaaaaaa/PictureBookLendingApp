import Foundation

/// クラス（組）データの永続化を管理するリポジトリのプロトコル
public protocol ClassGroupRepositoryProtocol {
    /// すべてのクラスを取得する
    func fetchAll() async throws -> [ClassGroup]
    
    /// 指定されたIDのクラスを取得する
    func fetch(by id: UUID) async throws -> ClassGroup?
    
    /// クラスを保存する（新規作成または更新）
    func save(_ classGroup: ClassGroup) async throws
    
    /// 指定されたIDのクラスを削除する
    func delete(by id: UUID) async throws
}
