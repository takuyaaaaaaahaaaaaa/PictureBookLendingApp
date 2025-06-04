import Foundation
import PictureBookLendingDomain
import SwiftData

/**
 * リポジトリファクトリプロトコル
 *
 * リポジトリのインスタンスを生成するためのファクトリのインターフェース
 */
protocol RepositoryFactory {
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
class SwiftDataRepositoryFactory: RepositoryFactory {
    private let modelContext: ModelContext
    
    /**
     * イニシャライザ
     *
     * - Parameter modelContext: SwiftData用のモデルコンテキスト
     */
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /**
     * 書籍リポジトリのインスタンスを生成
     *
     * - Returns: BookRepositoryのインスタンス
     */
    func makeBookRepository() -> BookRepository {
        return SwiftDataBookRepository(modelContext: modelContext)
    }
    
    /**
     * 利用者リポジトリのインスタンスを生成
     *
     * - Returns: UserRepositoryのインスタンス
     */
    func makeUserRepository() -> UserRepository {
        return SwiftDataUserRepository(modelContext: modelContext)
    }
    
    /**
     * 貸出リポジトリのインスタンスを生成
     *
     * - Returns: LoanRepositoryのインスタンス
     */
    func makeLoanRepository() -> LoanRepository {
        return SwiftDataLoanRepository(modelContext: modelContext)
    }
}

/**
 * メモリ内リポジトリファクトリ（テスト用）
 *
 * テスト用にメモリ内でデータを管理するリポジトリのインスタンスを生成するファクトリ
 */
class InMemoryRepositoryFactory: RepositoryFactory {
    /**
     * 書籍リポジトリのインスタンスを生成
     *
     * - Returns: BookRepositoryのインスタンス
     */
    func makeBookRepository() -> BookRepository {
        // 注：実際のInMemoryBookRepositoryの実装は省略されていますが、必要に応じて実装できます
        fatalError("Not yet implemented")
    }
    
    /**
     * 利用者リポジトリのインスタンスを生成
     *
     * - Returns: UserRepositoryのインスタンス
     */
    func makeUserRepository() -> UserRepository {
        // 注：実際のInMemoryUserRepositoryの実装は省略されていますが、必要に応じて実装できます
        fatalError("Not yet implemented")
    }
    
    /**
     * 貸出リポジトリのインスタンスを生成
     *
     * - Returns: LoanRepositoryのインスタンス
     */
    func makeLoanRepository() -> LoanRepository {
        // 注：実際のInMemoryLoanRepositoryの実装は省略されていますが、必要に応じて実装できます
        fatalError("Not yet implemented")
    }
}
