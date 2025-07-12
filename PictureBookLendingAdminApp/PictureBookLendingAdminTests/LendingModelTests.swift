import XCTest
import Foundation
@testable import PictureBookLendingAdmin
import PictureBookLendingDomain
import PictureBookLendingInfrastructure

/**
 * LendingModelテストケース
 *
 * 絵本の貸出・返却を管理するモデルの基本機能をテストします。
 */
final class LendingModelTests: XCTestCase {
    
    private var mockRepositoryFactory: MockRepositoryFactory!
    private var bookModel: BookModel!
    private var userModel: UserModel!
    private var lendingModel: LendingModel!
    
    private var testBook: Book!
    private var testUser: User!
    
    override func setUp() {
        super.setUp()
        do {
            try setUpModels()
        } catch {
            XCTFail("Failed to set up models: \(error)")
        }
    }
    
    private func setUpModels() throws {
        // テスト用に各モデルを初期化
        mockRepositoryFactory = MockRepositoryFactory()
        
        bookModel = BookModel(repository: mockRepositoryFactory.bookRepository)
        userModel = UserModel(repository: mockRepositoryFactory.userRepository)
        lendingModel = LendingModel(
            bookModel: bookModel,
            userModel: userModel,
            repository: mockRepositoryFactory.loanRepository
        )
        
        // テスト用データのセットアップ
        let initialBook = Book(title: "はらぺこあおむし", author: "エリック・カール")
        let initialUser = User(name: "山田太郎", group: "1年2組")
        
        // 本とユーザーを登録
        testBook = try bookModel.registerBook(initialBook)
        testUser = try userModel.registerUser(initialUser)
    }
    
    /**
     * 書籍貸出機能のテスト
     */
    func testLendBook() throws {
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let loan = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        
        XCTAssertEqual(loan.bookId, bookId)
        XCTAssertEqual(loan.userId, userId)
        XCTAssertEqual(loan.dueDate, dueDate)
        XCTAssertNil(loan.returnedDate)
        XCTAssertFalse(loan.isReturned)
        
        let activeLoans = lendingModel.getActiveLoans()
        XCTAssertEqual(activeLoans.count, 1)
        XCTAssertEqual(activeLoans.first?.bookId, bookId)
    }
    
    /**
     * 書籍返却機能のテスト
     */
    func testReturnBook() throws {
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let loan = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        let loanId = loan.id
        
        let returnedLoan = try lendingModel.returnBook(loanId: loanId)
        
        XCTAssertNotNil(returnedLoan.returnedDate)
        XCTAssertTrue(returnedLoan.isReturned)
        
        let activeLoans = lendingModel.getActiveLoans()
        XCTAssertEqual(activeLoans.count, 0)
        
        let allLoans = lendingModel.getAllLoans()
        XCTAssertEqual(allLoans.count, 1)
        XCTAssertTrue(allLoans.first?.isReturned ?? false)
    }
}