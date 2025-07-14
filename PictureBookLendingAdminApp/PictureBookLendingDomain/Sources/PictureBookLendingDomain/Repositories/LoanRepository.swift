import Foundation

/// 貸出リポジトリプロトコル
///
/// 貸出情報の永続化を担当するリポジトリのインターフェース
public protocol LoanRepository {
    /// 貸出情報を保存する
    ///
    /// - Parameter loan: 保存する貸出情報
    /// - Returns: 保存された貸出情報
    /// - Throws: 保存に失敗した場合はエラーを投げる
    func save(_ loan: Loan) throws -> Loan
    
    /// 全ての貸出情報を取得する
    ///
    /// - Returns: 全ての貸出情報のリスト
    /// - Throws: 取得に失敗した場合はエラーを投げる
    func fetchAll() throws -> [Loan]
    
    /// IDで貸出情報を検索する
    ///
    /// - Parameter id: 検索する貸出情報のID
    /// - Returns: 見つかった貸出情報（見つからない場合はnil）
    /// - Throws: 検索に失敗した場合はエラーを投げる
    func findById(_ id: UUID) throws -> Loan?
    
    /// 特定の絵本に関連する貸出情報を検索する
    ///
    /// - Parameter bookId: 検索する絵本のID
    /// - Returns: 関連する貸出情報のリスト
    /// - Throws: 検索に失敗した場合はエラーを投げる
    func findByBookId(_ bookId: UUID) throws -> [Loan]
    
    /// 特定の利用者に関連する貸出情報を検索する
    ///
    /// - Parameter userId: 検索する利用者のID
    /// - Returns: 関連する貸出情報のリスト
    /// - Throws: 検索に失敗した場合はエラーを投げる
    func findByUserId(_ userId: UUID) throws -> [Loan]
    
    /// 現在貸出中の貸出情報を取得する
    ///
    /// - Returns: 貸出中の貸出情報のリスト
    /// - Throws: 取得に失敗した場合はエラーを投げる
    func fetchActiveLoans() throws -> [Loan]
    
    /// 貸出情報を更新する
    ///
    /// - Parameter loan: 更新する貸出情報
    /// - Returns: 更新された貸出情報
    /// - Throws: 更新に失敗した場合はエラーを投げる
    func update(_ loan: Loan) throws -> Loan
    
    /// 貸出情報を削除する
    ///
    /// - Parameter id: 削除する貸出情報のID
    /// - Returns: 削除に成功したかどうか
    /// - Throws: 削除に失敗した場合はエラーを投げる
    func delete(_ id: UUID) throws -> Bool
}
