import PictureBookLendingDomain
import SwiftData

/// リポジトリファクトリプロトコル
///
/// リポジトリのインスタンスを生成するためのファクトリのインターフェース
public protocol RepositoryFactory {
    /// 書籍リポジトリを生成
    /// - Returns: BookRepositoryのインスタンス
    func makeBookRepository() -> BookRepository
    
    /// 利用者リポジトリを生成
    func makeUserRepository() -> UserRepository
    
    /// 貸出リポジトリを生成
    func makeLoanRepository() -> LoanRepository
    
    /// クラス（組）リポジトリを生成
    func makeClassGroupRepository() -> ClassGroupRepository
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
    /// - Returns: BookRepositoryのインスタンス
    public func makeBookRepository() -> BookRepository {
        SwiftDataBookRepository(modelContext: modelContext)
    }
    
    /// 利用者リポジトリのインスタンスを生成
    ///
    /// - Returns: UserRepositoryのインスタンス
    public func makeUserRepository() -> UserRepository {
        SwiftDataUserRepository(modelContext: modelContext)
    }
    
    /// 貸出リポジトリのインスタンスを生成
    ///
    /// - Returns: LoanRepositoryのインスタンス
    public func makeLoanRepository() -> LoanRepository {
        SwiftDataLoanRepository(modelContext: modelContext)
    }
    
    /// クラス（組）リポジトリのインスタンスを生成
    ///
    /// - Returns: ClassGroupRepositoryのインスタンス
    public func makeClassGroupRepository() -> ClassGroupRepository {
        SwiftDataClassGroupRepository(modelContext: modelContext)
    }
}
