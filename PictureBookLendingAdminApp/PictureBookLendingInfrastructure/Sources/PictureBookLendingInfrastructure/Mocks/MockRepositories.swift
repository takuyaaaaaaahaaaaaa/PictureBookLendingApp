import Foundation
import PictureBookLendingDomain

/// テスト用のモックブックリポジトリ
public class MockBookRepository: BookRepository {
    private var books: [Book] = []
    
    public init() {}
    
    public func save(_ book: Book) throws -> Book {
        if books.contains(where: { $0.id == book.id }) {
            throw RepositoryError.saveFailed
        }
        books.append(book)
        return book
    }
    
    public func fetchAll() throws -> [Book] {
        return books
    }
    
    public func findById(_ id: UUID) throws -> Book? {
        return books.first { $0.id == id }
    }
    
    public func update(_ book: Book) throws -> Book {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else {
            throw RepositoryError.notFound
        }
        books[index] = book
        return book
    }
    
    public func delete(_ id: UUID) throws -> Bool {
        guard let index = books.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        books.remove(at: index)
        return true
    }
}

/// テスト用のモックユーザーリポジトリ
public class MockUserRepository: UserRepository {
    private var users: [User] = []
    
    public init() {}
    
    public func save(_ user: User) throws -> User {
        if users.contains(where: { $0.id == user.id }) {
            throw RepositoryError.saveFailed
        }
        users.append(user)
        return user
    }
    
    public func fetchAll() throws -> [User] {
        return users
    }
    
    public func findById(_ id: UUID) throws -> User? {
        return users.first { $0.id == id }
    }
    
    public func update(_ user: User) throws -> User {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            throw RepositoryError.notFound
        }
        users[index] = user
        return user
    }
    
    public func delete(_ id: UUID) throws -> Bool {
        guard let index = users.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        users.remove(at: index)
        return true
    }
}

/// テスト用のモック貸出リポジトリ
public class MockLoanRepository: LoanRepository {
    private var loans: [Loan] = []
    
    public init() {}
    
    public func save(_ loan: Loan) throws -> Loan {
        if loans.contains(where: { $0.id == loan.id }) {
            throw RepositoryError.saveFailed
        }
        loans.append(loan)
        return loan
    }
    
    public func fetchAll() throws -> [Loan] {
        return loans
    }
    
    public func findById(_ id: UUID) throws -> Loan? {
        return loans.first { $0.id == id }
    }
    
    public func findByBookId(_ bookId: UUID) throws -> [Loan] {
        return loans.filter { $0.bookId == bookId }
    }
    
    public func findByUserId(_ userId: UUID) throws -> [Loan] {
        return loans.filter { $0.userId == userId }
    }
    
    public func fetchActiveLoans() throws -> [Loan] {
        return loans.filter { $0.returnedDate == nil }
    }
    
    public func update(_ loan: Loan) throws -> Loan {
        guard let index = loans.firstIndex(where: { $0.id == loan.id }) else {
            throw RepositoryError.notFound
        }
        loans[index] = loan
        return loan
    }
    
    public func delete(_ id: UUID) throws -> Bool {
        guard let index = loans.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        loans.remove(at: index)
        return true
    }
}

/// テスト用のモックリポジトリファクトリ
public class MockRepositoryFactory: RepositoryFactory {
    public let bookRepository = MockBookRepository()
    public let userRepository = MockUserRepository()
    public let loanRepository = MockLoanRepository()
    
    public init() {}
    
    public func makeBookRepository() -> BookRepository {
        return bookRepository
    }
    
    public func makeUserRepository() -> UserRepository {
        return userRepository
    }
    
    public func makeLoanRepository() -> LoanRepository {
        return loanRepository
    }
}
