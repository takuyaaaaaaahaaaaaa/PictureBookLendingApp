import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingModel

// テスト用のモック貸出設定リポジトリ
private final class MockLoanSettingsRepository: LoanSettingsRepositoryProtocol, @unchecked Sendable
{
    private let lock = NSLock()
    private var settings: LoanSettings = LoanSettings.default
    
    func fetch() -> LoanSettings {
        lock.lock()
        defer { lock.unlock() }
        return settings
    }
    
    func save(_ newSettings: LoanSettings) throws {
        lock.lock()
        defer { lock.unlock() }
        self.settings = newSettings
    }
}

/// LoanModelテストケース
///
/// 絵本の貸出・返却を管理するモデルの基本機能をテストします。
@Suite("LoanModel Tests")
struct LoanModelTests {
    
    private func createLoanModel() throws -> (
        mockRepositoryFactory: MockRepositoryFactory, bookModel: BookModel, userModel: UserModel,
        loanModel: LoanModel, testBook: Book, testUser: User
    ) {
        // テスト用に各モデルを初期化
        let mockRepositoryFactory = MockRepositoryFactory()
        
        let bookModel = BookModel(repository: mockRepositoryFactory.bookRepository)
        let userModel = UserModel(repository: mockRepositoryFactory.userRepository)
        let loanSettingsRepository = MockLoanSettingsRepository()
        let loanModel = LoanModel(
            repository: mockRepositoryFactory.loanRepository,
            bookRepository: mockRepositoryFactory.bookRepository,
            userRepository: mockRepositoryFactory.userRepository,
            loanSettingsRepository: loanSettingsRepository
        )
        
        // テスト用データのセットアップ
        // まずクラスグループを作成
        let classGroup = ClassGroup(name: "1年2組", ageGroup: 6, year: 2025)
        try mockRepositoryFactory.classGroupRepository.save(classGroup)
        
        let initialBook = Book(title: "はらぺこあおむし", author: "エリック・カール")
        let initialUser = User(name: "山田太郎", classGroupId: classGroup.id)
        
        // 本とユーザーを登録
        let testBook = try bookModel.registerBook(initialBook)
        let testUser = try userModel.registerUser(initialUser)
        
        return (mockRepositoryFactory, bookModel, userModel, loanModel, testBook, testUser)
    }
    
    /// 絵本貸出機能のテスト
    @Test("絵本貸出機能のテスト")
    func lendBook() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let loan = try loanModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        
        #expect(loan.bookId == bookId)
        #expect(loan.userId == userId)
        #expect(loan.dueDate == dueDate)
        #expect(loan.returnedDate == nil)
        #expect(loan.isReturned == false)
        
        let activeLoans = loanModel.getActiveLoans()
        #expect(activeLoans.count == 1)
        #expect(activeLoans.first?.bookId == bookId)
    }
    
    /// 絵本返却機能のテスト
    @Test("絵本返却機能のテスト")
    func returnBook() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let loan = try loanModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        let loanId = loan.id
        
        let returnedLoan = try loanModel.returnBook(loanId: loanId)
        
        #expect(returnedLoan.returnedDate != nil)
        #expect(returnedLoan.isReturned == true)
        
        let activeLoans = loanModel.getActiveLoans()
        #expect(activeLoans.count == 0)
        
        let allLoans = loanModel.getAllLoans()
        #expect(allLoans.count == 1)
        #expect(allLoans.first?.isReturned == true)
    }
    
    /// 絵本IDから返却機能のテスト
    @Test("絵本IDから返却機能のテスト")
    func returnBookByBookId() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let loan = try loanModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        
        // 貸出中であることを確認
        #expect(loanModel.isBookLent(bookId: bookId) == true)
        
        // 絵本IDで返却処理を実行
        let returnedLoan = try loanModel.returnBook(bookId: bookId)
        
        #expect(returnedLoan.id == loan.id)
        #expect(returnedLoan.returnedDate != nil)
        #expect(returnedLoan.isReturned == true)
        
        // 返却後は貸出中でないことを確認
        #expect(loanModel.isBookLent(bookId: bookId) == false)
        
        let activeLoans = loanModel.getActiveLoans()
        #expect(activeLoans.count == 0)
        
        let allLoans = loanModel.getAllLoans()
        #expect(allLoans.count == 1)
        #expect(allLoans.first?.isReturned == true)
    }
    
    /// 貸出中でない絵本を返却しようとするとエラーが発生することのテスト
    @Test("貸出中でない絵本を返却しようとするとエラーが発生することのテスト")
    func returnBookNotLent() throws {
        let (_, _, _, loanModel, testBook, _) = try createLoanModel()
        
        let bookId = testBook.id
        
        // 貸出中でないことを確認
        #expect(loanModel.isBookLent(bookId: bookId) == false)
        
        // 貸出中でない絵本を返却しようとするとエラーが発生することを確認
        #expect(throws: LoanModelError.loanNotFound) {
            try loanModel.returnBook(bookId: bookId)
        }
    }
}
