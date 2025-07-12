import Foundation
import PictureBookLendingDomain
import SwiftData

/**
 * リポジトリファクトリプロトコル
 *
 * リポジトリのインスタンスを生成するためのファクトリのインターフェース
 */
public protocol RepositoryFactory {
    /// 書籍リポジトリを生成
    /// - Returns: <#description#>
    func makeBookRepository() -> BookRepository
    
    /// 利用者リポジトリを生成
    func makeUserRepository() -> UserRepository
    
    /// 貸出リポジトリを生成
    func makeLoanRepository() -> LoanRepository
}

/**
 * SwiftData用リポジトリファクトリ実装
 *
 * SwiftDataを使用してリポジトリのインスタンスを生成するファクトリ
 */
public class SwiftDataRepositoryFactory: RepositoryFactory {
    private let modelContext: ModelContext
    
    /**
     * イニシャライザ
     *
     * - Parameter modelContext: SwiftData用のモデルコンテキスト
     */
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /**
     * 書籍リポジトリのインスタンスを生成
     *
     * - Returns: BookRepositoryのインスタンス
     */
    public func makeBookRepository() -> BookRepository {
        return SwiftDataBookRepository(modelContext: modelContext)
    }
    
    /**
     * 利用者リポジトリのインスタンスを生成
     *
     * - Returns: UserRepositoryのインスタンス
     */
    public func makeUserRepository() -> UserRepository {
        return SwiftDataUserRepository(modelContext: modelContext)
    }
    
    /**
     * 貸出リポジトリのインスタンスを生成
     *
     * - Returns: LoanRepositoryのインスタンス
     */
    public func makeLoanRepository() -> LoanRepository {
        return SwiftDataLoanRepository(modelContext: modelContext)
    }
}
