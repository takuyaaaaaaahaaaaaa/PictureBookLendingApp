import Foundation
import PictureBookLendingDomain

/// テスト用のモックブックリポジトリ
public final class MockBookRepository: BookRepositoryProtocol, @unchecked Sendable {
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
public final class MockUserRepository: UserRepositoryProtocol, @unchecked Sendable {
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
public final class MockLoanRepository: LoanRepositoryProtocol, @unchecked Sendable {
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

/// テスト用のモッククラス（組）リポジトリ
public final class MockClassGroupRepository: ClassGroupRepositoryProtocol, @unchecked Sendable {
    private var classGroups: [ClassGroup] = []
    
    public init() {}
    
    public func fetchAll() throws -> [ClassGroup] {
        return classGroups
    }
    
    public func fetch(by id: UUID) throws -> ClassGroup? {
        return classGroups.first { $0.id == id }
    }
    
    public func save(_ classGroup: ClassGroup) throws {
        if let index = classGroups.firstIndex(where: { $0.id == classGroup.id }) {
            classGroups[index] = classGroup
        } else {
            classGroups.append(classGroup)
        }
    }
    
    public func delete(by id: UUID) throws {
        guard let index = classGroups.firstIndex(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        classGroups.remove(at: index)
    }
}

/// テスト用のモック貸出設定リポジトリ
public final class MockLoanSettingsRepository: LoanSettingsRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _settings: LoanSettings = .default
    
    public init() {}
    
    public func fetch() -> LoanSettings {
        lock.lock()
        defer { lock.unlock() }
        return _settings
    }
    
    public func save(_ newSettings: LoanSettings) throws {
        lock.lock()
        defer { lock.unlock() }
        _settings = newSettings
    }
}

/// テスト用のモックリポジトリファクトリ
public final class MockRepositoryFactory: RepositoryFactory {
    public let bookRepository = MockBookRepository()
    public let userRepository = MockUserRepository()
    public let loanRepository = MockLoanRepository()
    public let classGroupRepository = MockClassGroupRepository()
    public let loanSettingsRepository = MockLoanSettingsRepository()
    
    public init() {}
    
    public func makeBookRepository() -> BookRepositoryProtocol {
        return bookRepository
    }
    
    public func makeUserRepository() -> UserRepositoryProtocol {
        return userRepository
    }
    
    public func makeLoanRepository() -> LoanRepositoryProtocol {
        return loanRepository
    }
    
    public func makeClassGroupRepository() -> ClassGroupRepositoryProtocol {
        return classGroupRepository
    }
    
    public func makeLoanSettingsRepository() -> LoanSettingsRepositoryProtocol {
        return loanSettingsRepository
    }
    
    public func makeBookSearchGateway() -> BookSearchGatewayProtocol {
        return MockBookSearchGateway()
    }
}

/// テスト用のモック書籍検索ゲートウェイ
public final class MockBookSearchGateway: BookSearchGatewayProtocol {
    public init() {}
    
    public func searchBook(by isbn: String) async throws -> Book {
        // テスト用のサンプルデータを返す
        return Book(
            title: "テスト用絵本(\(isbn))",
            author: "テスト著者",
            isbn13: isbn,
            publisher: "テスト出版社",
            publishedDate: "2023-01-01",
            description: "これはテスト用の絵本です。",
            smallThumbnail: "https://example.com/small-thumbnail.jpg",
            thumbnail: "https://example.com/thumbnail.jpg",
            targetAge: 3,
            pageCount: 32,
            categories: ["絵本", "テスト"]
        )
    }
    
    public func searchBooks(title: String, author: String?, maxResults: Int) async throws -> [Book]
    {
        // テスト用の複数サンプルデータを返す
        var books: [Book] = []
        
        for i in 1...min(maxResults, 3) {
            let book = Book(
                title: "\(title) (\(i))",
                author: author ?? "テスト著者\(i)",
                isbn13: "978000000000\(i)",
                publisher: "テスト出版社\(i)",
                publishedDate: "2023-0\(i)-01",
                description: "これは\(title)のテスト用絵本です。",
                smallThumbnail: "https://example.com/small-thumbnail\(i).jpg",
                thumbnail: "https://example.com/thumbnail\(i).jpg",
                targetAge: 2 + i,
                pageCount: 30 + i * 2,
                categories: ["絵本", "テスト"]
            )
            books.append(book)
        }
        
        return books
    }
}
