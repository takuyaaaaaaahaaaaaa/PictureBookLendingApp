import Foundation
import PictureBookLendingCore
@testable import PictureBookLendingAdmin

/**
 * テスト用のモックブックリポジトリ
 */
class MockBookRepository: BookRepository {
    private var books: [Book] = []
    
    func save(_ book: Book) throws -> Book {
        if books.contains(where: { $0.id == book.id }) {
            throw RepositoryError.saveFailed
        }
        books.append(book)
        return book
    }
    
    func fetchAll() throws -> [Book] {
        return books
    }
    
    func findById(_ id: UUID) throws -> Book? {
        return books.first { $0.id == id }
    }
    
    func update(_ book: Book) throws -> Book {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else {
            throw RepositoryError.notFound
        }
        books[index] = book
        return book
    }
    
    func delete(_ id: UUID) throws -> Bool {
        guard let index = books.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        books.remove(at: index)
        return true
    }
}

/**
 * テスト用のモックユーザーリポジトリ
 */
class MockUserRepository: UserRepository {
    private var users: [User] = []
    
    func save(_ user: User) throws -> User {
        if users.contains(where: { $0.id == user.id }) {
            throw RepositoryError.saveFailed
        }
        users.append(user)
        return user
    }
    
    func fetchAll() throws -> [User] {
        return users
    }
    
    func findById(_ id: UUID) throws -> User? {
        return users.first { $0.id == id }
    }
    
    func update(_ user: User) throws -> User {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            throw RepositoryError.notFound
        }
        users[index] = user
        return user
    }
    
    func delete(_ id: UUID) throws -> Bool {
        guard let index = users.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        users.remove(at: index)
        return true
    }
}

/**
 * テスト用のモック貸出リポジトリ
 */
class MockLoanRepository: LoanRepository {
    private var loans: [Loan] = []
    
    func save(_ loan: Loan) throws -> Loan {
        if loans.contains(where: { $0.id == loan.id }) {
            throw RepositoryError.saveFailed
        }
        loans.append(loan)
        return loan
    }
    
    func fetchAll() throws -> [Loan] {
        return loans
    }
    
    func findById(_ id: UUID) throws -> Loan? {
        return loans.first { $0.id == id }
    }
    
    func findByBookId(_ bookId: UUID) throws -> [Loan] {
        return loans.filter { $0.bookId == bookId }
    }
    
    func findByUserId(_ userId: UUID) throws -> [Loan] {
        return loans.filter { $0.userId == userId }
    }
    
    func fetchActiveLoans() throws -> [Loan] {
        return loans.filter { $0.returnedDate == nil }
    }
    
    func update(_ loan: Loan) throws -> Loan {
        guard let index = loans.firstIndex(where: { $0.id == loan.id }) else {
            throw RepositoryError.notFound
        }
        loans[index] = loan
        return loan
    }
    
    func delete(_ id: UUID) throws -> Bool {
        guard let index = loans.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        loans.remove(at: index)
        return true
    }
}

/**
 * テスト用のモックリポジトリファクトリ
 */
class MockRepositoryFactory: RepositoryFactory {
    let bookRepository = MockBookRepository()
    let userRepository = MockUserRepository()
    let loanRepository = MockLoanRepository()
    
    func makeBookRepository() -> BookRepository {
        return bookRepository
    }
    
    func makeUserRepository() -> UserRepository {
        return userRepository
    }
    
    func makeLoanRepository() -> LoanRepository {
        return loanRepository
    }
}