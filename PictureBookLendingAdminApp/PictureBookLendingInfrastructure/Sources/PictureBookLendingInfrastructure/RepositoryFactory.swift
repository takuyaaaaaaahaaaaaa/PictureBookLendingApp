import PictureBookLendingDomain
import SwiftData

/// リポジトリファクトリプロトコル
///
/// リポジトリのインスタンスを生成するためのファクトリのインターフェース
public protocol RepositoryFactory {
    /// 書籍リポジトリを生成
    /// - Returns: BookRepositoryProtocolのインスタンス
    func makeBookRepository() -> BookRepositoryProtocol
    
    /// 利用者リポジトリを生成
    func makeUserRepository() -> UserRepositoryProtocol
    
    /// 貸出リポジトリを生成
    func makeLoanRepository() -> LoanRepositoryProtocol
    
    /// クラス（組）リポジトリを生成
    func makeClassGroupRepository() -> ClassGroupRepositoryProtocol
}

/// SwiftData用リポジトリファクトリ実装
///
/// SwiftDataを使用してリポジトリのインスタンスを生成するファクトリ
public class SwiftDataRepositoryFactory: RepositoryFactory {
    private let modelContext: ModelContext
    
    /// イニシャライザ
    ///
    /// - Parameter modelContext: SwiftData用のモデルコンテキスト
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 書籍リポジトリのインスタンスを生成
    ///
    /// - Returns: BookRepositoryProtocolのインスタンス
    public func makeBookRepository() -> BookRepositoryProtocol {
        SwiftDataBookRepository(modelContext: modelContext)
    }
    
    /// 利用者リポジトリのインスタンスを生成
    ///
    /// - Returns: UserRepositoryProtocolのインスタンス
    public func makeUserRepository() -> UserRepositoryProtocol {
        SwiftDataUserRepository(modelContext: modelContext)
    }
    
    /// 貸出リポジトリのインスタンスを生成
    ///
    /// - Returns: LoanRepositoryProtocolのインスタンス
    public func makeLoanRepository() -> LoanRepositoryProtocol {
        SwiftDataLoanRepository(modelContext: modelContext)
    }
    
    /// クラス（組）リポジトリのインスタンスを生成
    ///
    /// - Returns: ClassGroupRepositoryProtocolのインスタンス
    public func makeClassGroupRepository() -> ClassGroupRepositoryProtocol {
        SwiftDataClassGroupRepository(modelContext: modelContext)
    }
}
