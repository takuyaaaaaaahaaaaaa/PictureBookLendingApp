import Foundation
import PictureBookLendingDomain
import SwiftData

/**
 * SwiftData用貸出リポジトリ実装
 *
 * SwiftDataを使用して貸出情報の永続化を担当するリポジトリ
 */
public class SwiftDataLoanRepository: LoanRepository {
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
     * 貸出情報を保存する
     *
     * - Parameter loan: 保存する貸出情報
     * - Returns: 保存された貸出情報
     * - Throws: 保存に失敗した場合はエラーを投げる
     */
    public func save(_ loan: Loan) throws -> Loan {
        let swiftDataLoan = SwiftDataLoan(
            id: loan.id,
            bookId: loan.bookId,
            userId: loan.userId,
            loanDate: loan.loanDate,
            dueDate: loan.dueDate,
            returnedDate: loan.returnedDate
        )
        
        modelContext.insert(swiftDataLoan)
        
        do {
            try modelContext.save()
            return loan
        } catch {
            throw RepositoryError.saveFailed
        }
    }
    
    /**
     * 全ての貸出情報を取得する
     *
     * - Returns: 全ての貸出情報のリスト
     * - Throws: 取得に失敗した場合はエラーを投げる
     */
    public func fetchAll() throws -> [Loan] {
        do {
            let descriptor = FetchDescriptor<SwiftDataLoan>()
            let swiftDataLoans = try modelContext.fetch(descriptor)
            
            return swiftDataLoans.map { swiftDataLoan in
                Loan(
                    id: swiftDataLoan.id,
                    bookId: swiftDataLoan.bookId,
                    userId: swiftDataLoan.userId,
                    loanDate: swiftDataLoan.loanDate,
                    dueDate: swiftDataLoan.dueDate,
                    returnedDate: swiftDataLoan.returnedDate
                )
            }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /**
     * IDで貸出情報を検索する
     *
     * - Parameter id: 検索する貸出情報のID
     * - Returns: 見つかった貸出情報（見つからない場合はnil）
     * - Throws: 検索に失敗した場合はエラーを投げる
     */
    public func findById(_ id: UUID) throws -> Loan? {
        do {
            let predicate = #Predicate<SwiftDataLoan> { $0.id == id }
            let descriptor = FetchDescriptor<SwiftDataLoan>(predicate: predicate)
            
            let swiftDataLoans = try modelContext.fetch(descriptor)
            guard let swiftDataLoan = swiftDataLoans.first else {
                return nil
            }
            
            return Loan(
                id: swiftDataLoan.id,
                bookId: swiftDataLoan.bookId,
                userId: swiftDataLoan.userId,
                loanDate: swiftDataLoan.loanDate,
                dueDate: swiftDataLoan.dueDate,
                returnedDate: swiftDataLoan.returnedDate
            )
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /**
     * 特定の絵本に関連する貸出情報を検索する
     *
     * - Parameter bookId: 検索する絵本のID
     * - Returns: 関連する貸出情報のリスト
     * - Throws: 検索に失敗した場合はエラーを投げる
     */
    public func findByBookId(_ bookId: UUID) throws -> [Loan] {
        do {
            let predicate = #Predicate<SwiftDataLoan> { $0.bookId == bookId }
            let descriptor = FetchDescriptor<SwiftDataLoan>(predicate: predicate)
            
            let swiftDataLoans = try modelContext.fetch(descriptor)
            return swiftDataLoans.map { swiftDataLoan in
                Loan(
                    id: swiftDataLoan.id,
                    bookId: swiftDataLoan.bookId,
                    userId: swiftDataLoan.userId,
                    loanDate: swiftDataLoan.loanDate,
                    dueDate: swiftDataLoan.dueDate,
                    returnedDate: swiftDataLoan.returnedDate
                )
            }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /**
     * 特定の利用者に関連する貸出情報を検索する
     *
     * - Parameter userId: 検索する利用者のID
     * - Returns: 関連する貸出情報のリスト
     * - Throws: 検索に失敗した場合はエラーを投げる
     */
    public func findByUserId(_ userId: UUID) throws -> [Loan] {
        do {
            let predicate = #Predicate<SwiftDataLoan> { $0.userId == userId }
            let descriptor = FetchDescriptor<SwiftDataLoan>(predicate: predicate)
            
            let swiftDataLoans = try modelContext.fetch(descriptor)
            return swiftDataLoans.map { swiftDataLoan in
                Loan(
                    id: swiftDataLoan.id,
                    bookId: swiftDataLoan.bookId,
                    userId: swiftDataLoan.userId,
                    loanDate: swiftDataLoan.loanDate,
                    dueDate: swiftDataLoan.dueDate,
                    returnedDate: swiftDataLoan.returnedDate
                )
            }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /**
     * 現在貸出中の貸出情報を取得する
     *
     * - Returns: 貸出中の貸出情報のリスト
     * - Throws: 取得に失敗した場合はエラーを投げる
     */
    public func fetchActiveLoans() throws -> [Loan] {
        do {
            let predicate = #Predicate<SwiftDataLoan> { $0.returnedDate == nil }
            let descriptor = FetchDescriptor<SwiftDataLoan>(predicate: predicate)
            
            let swiftDataLoans = try modelContext.fetch(descriptor)
            return swiftDataLoans.map { swiftDataLoan in
                Loan(
                    id: swiftDataLoan.id,
                    bookId: swiftDataLoan.bookId,
                    userId: swiftDataLoan.userId,
                    loanDate: swiftDataLoan.loanDate,
                    dueDate: swiftDataLoan.dueDate,
                    returnedDate: swiftDataLoan.returnedDate
                )
            }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /**
     * 貸出情報を更新する
     *
     * - Parameter loan: 更新する貸出情報
     * - Returns: 更新された貸出情報
     * - Throws: 更新に失敗した場合はエラーを投げる
     */
    public func update(_ loan: Loan) throws -> Loan {
        do {
            let predicate = #Predicate<SwiftDataLoan> { $0.id == loan.id }
            let descriptor = FetchDescriptor<SwiftDataLoan>(predicate: predicate)
            
            let swiftDataLoans = try modelContext.fetch(descriptor)
            guard let swiftDataLoan = swiftDataLoans.first else {
                throw RepositoryError.notFound
            }
            
            // プロパティを更新
            swiftDataLoan.bookId = loan.bookId
            swiftDataLoan.userId = loan.userId
            swiftDataLoan.loanDate = loan.loanDate
            swiftDataLoan.dueDate = loan.dueDate
            swiftDataLoan.returnedDate = loan.returnedDate
            
            try modelContext.save()
            
            return loan
        } catch RepositoryError.notFound {
            throw RepositoryError.notFound
        } catch {
            throw RepositoryError.updateFailed
        }
    }
    
    /**
     * 貸出情報を削除する
     *
     * - Parameter id: 削除する貸出情報のID
     * - Returns: 削除に成功したかどうか
     * - Throws: 削除に失敗した場合はエラーを投げる
     */
    public func delete(_ id: UUID) throws -> Bool {
        do {
            let predicate = #Predicate<SwiftDataLoan> { $0.id == id }
            let descriptor = FetchDescriptor<SwiftDataLoan>(predicate: predicate)
            
            let swiftDataLoans = try modelContext.fetch(descriptor)
            guard let swiftDataLoan = swiftDataLoans.first else {
                throw RepositoryError.notFound
            }
            
            modelContext.delete(swiftDataLoan)
            try modelContext.save()
            
            return true
        } catch RepositoryError.notFound {
            throw RepositoryError.notFound
        } catch {
            throw RepositoryError.deleteFailed
        }
    }
}

/**
 * SwiftData用の貸出モデル
 *
 * SwiftDataで永続化するための貸出モデル
 */
@Model
final public class SwiftDataLoan {
    public var id: UUID
    public var bookId: UUID
    public var userId: UUID
    public var loanDate: Date
    public var dueDate: Date
    public var returnedDate: Date?
    
    public init(id: UUID, bookId: UUID, userId: UUID, loanDate: Date, dueDate: Date, returnedDate: Date? = nil) {
        self.id = id
        self.bookId = bookId
        self.userId = userId
        self.loanDate = loanDate
        self.dueDate = dueDate
        self.returnedDate = returnedDate
    }
}