import Testing
import Foundation
@testable import PictureBookLendingModel
import PictureBookLendingDomain

/**
 * LendingModelテストケース
 *
 * 絵本の貸出・返却を管理するモデルの基本機能をテストします。
 */
@Suite("LendingModel Tests")
struct LendingModelTests {
    
    private func createLendingModel() throws -> (mockRepositoryFactory: MockRepositoryFactory, bookModel: BookModel, userModel: UserModel, lendingModel: LendingModel, testBook: Book, testUser: User) {
        // テスト用に各モデルを初期化
        let mockRepositoryFactory = MockRepositoryFactory()
        
        let bookModel = BookModel(repository: mockRepositoryFactory.bookRepository)
        let userModel = UserModel(repository: mockRepositoryFactory.userRepository)
        let lendingModel = LendingModel(
            repository: mockRepositoryFactory.loanRepository,
            bookRepository: mockRepositoryFactory.bookRepository,
            userRepository: mockRepositoryFactory.userRepository
        )
        
        // テスト用データのセットアップ
        let initialBook = Book(title: "はらぺこあおむし", author: "エリック・カール")
        let initialUser = User(name: "山田太郎", group: "1年2組")
        
        // 本とユーザーを登録
        let testBook = try bookModel.registerBook(initialBook)
        let testUser = try userModel.registerUser(initialUser)
        
        return (mockRepositoryFactory, bookModel, userModel, lendingModel, testBook, testUser)
    }
    
    /**
     * 書籍貸出機能のテスト
     */
    @Test("書籍貸出機能のテスト")
    func lendBook() throws {
        let (_, _, _, lendingModel, testBook, testUser) = try createLendingModel()
        
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let loan = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        
        #expect(loan.bookId == bookId)
        #expect(loan.userId == userId)
        #expect(loan.dueDate == dueDate)
        #expect(loan.returnedDate == nil)
        #expect(loan.isReturned == false)
        
        let activeLoans = lendingModel.getActiveLoans()
        #expect(activeLoans.count == 1)
        #expect(activeLoans.first?.bookId == bookId)
    }
    
    /**
     * 書籍返却機能のテスト
     */
    @Test("書籍返却機能のテスト")
    func returnBook() throws {
        let (_, _, _, lendingModel, testBook, testUser) = try createLendingModel()
        
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let loan = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        let loanId = loan.id
        
        let returnedLoan = try lendingModel.returnBook(loanId: loanId)
        
        #expect(returnedLoan.returnedDate != nil)
        #expect(returnedLoan.isReturned == true)
        
        let activeLoans = lendingModel.getActiveLoans()
        #expect(activeLoans.count == 0)
        
        let allLoans = lendingModel.getAllLoans()
        #expect(allLoans.count == 1)
        #expect(allLoans.first?.isReturned == true)
    }
}