import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingModel

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
        let loanModel = LoanModel(
            repository: mockRepositoryFactory.loanRepository,
            bookRepository: mockRepositoryFactory.bookRepository,
            userRepository: mockRepositoryFactory.userRepository,
            loanSettingsRepository: mockRepositoryFactory.loanSettingsRepository
        )
        
        // テスト用データのセットアップ
        let initialBook = Book(title: "はらぺこあおむし", author: "エリック・カール")
        let initialUser = User(name: "山田太郎", group: "1年2組")
        
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
}
