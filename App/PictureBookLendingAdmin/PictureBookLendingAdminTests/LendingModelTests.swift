import XCTest
import PictureBookLendingCore
@testable import PictureBookLendingAdmin

/**
 * LendingModelテストケース
 *
 * 絵本の貸出・返却を管理するモデルの機能をテストするためのケース集です。
 * - 絵本の貸出処理
 * - 絵本の返却処理
 * - 貸出中の絵本の取得
 * - ユーザーごとの貸出履歴取得
 * - 絵本ごとの貸出履歴取得
 * などの機能をテストします。
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
        testBook = Book(title: "はらぺこあおむし", author: "エリック・カール")
        testUser = User(name: "山田太郎", group: "1年2組")
        
        do {
            // 本とユーザーを登録
            testBook = try bookModel.registerBook(testBook)
            testUser = try userModel.registerUser(testUser)
        } catch {
            XCTFail("セットアップ中にエラーが発生しました: \(error)")
        }
    }
    
    override func tearDown() {
        mockRepositoryFactory = nil
        bookModel = nil
        userModel = nil
        lendingModel = nil
        testBook = nil
        testUser = nil
        super.tearDown()
    }
    
    /**
     * 書籍貸出機能のテスト
     *
     * 絵本をユーザーに貸し出し、正しく貸出記録が作成されることを確認します。
     */
    func testLendBook() throws {
        // 1. Arrange - 準備
        let bookId = testBook.id
        let userId = testUser.id
        
        // 2. Act - 実行
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let loan = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        
        // 3. Assert - 検証
        XCTAssertEqual(loan.bookId, bookId)
        XCTAssertEqual(loan.userId, userId)
        XCTAssertEqual(loan.dueDate, dueDate)
        XCTAssertNil(loan.returnedDate)
        XCTAssertFalse(loan.isReturned)
        
        // 貸出中の本リストにあることを確認
        let activeLoans = lendingModel.getActiveLoans()
        XCTAssertEqual(activeLoans.count, 1)
        XCTAssertEqual(activeLoans.first?.bookId, bookId)
    }
    
    /**
     * 貸出中書籍の重複貸出防止テスト
     *
     * すでに貸出中の絵本を再度貸し出そうとした場合、
     * 適切なエラーが発生することを確認します。
     */
    func testLendBookAlreadyLent() throws {
        // 1. Arrange - 準備
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        _ = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        
        // 2. Act & Assert - 実行と検証
        XCTAssertThrowsError(try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)) { error in
            XCTAssertEqual(error as? LendingModelError, LendingModelError.bookAlreadyLent)
        }
    }
    
    /**
     * 存在しない書籍の貸出テスト
     *
     * 存在しない絵本IDを指定して貸出を試みた場合、
     * 適切なエラーが発生することを確認します。
     */
    func testLendNonExistingBook() throws {
        // 1. Arrange - 準備
        let nonExistingBookId = UUID()
        let userId = testUser.id
        
        // 2. Act & Assert - 実行と検証
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        XCTAssertThrowsError(try lendingModel.lendBook(bookId: nonExistingBookId, userId: userId, dueDate: dueDate)) { error in
            XCTAssertEqual(error as? LendingModelError, LendingModelError.bookNotFound)
        }
    }
    
    /**
     * 存在しないユーザーへの貸出テスト
     *
     * 存在しないユーザーIDを指定して貸出を試みた場合、
     * 適切なエラーが発生することを確認します。
     */
    func testLendToNonExistingUser() throws {
        // 1. Arrange - 準備
        let nonExistingUserId = UUID()
        let bookId = testBook.id
        
        // 2. Act & Assert - 実行と検証
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        XCTAssertThrowsError(try lendingModel.lendBook(bookId: bookId, userId: nonExistingUserId, dueDate: dueDate)) { error in
            XCTAssertEqual(error as? LendingModelError, LendingModelError.userNotFound)
        }
    }
    
    /**
     * 書籍返却機能のテスト
     *
     * 貸出中の絵本を返却し、正しく返却記録が更新されることを確認します。
     */
    func testReturnBook() throws {
        // 1. Arrange - 準備
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let loan = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        let loanId = loan.id
        
        // 2. Act - 実行
        let returnedLoan = try lendingModel.returnBook(loanId: loanId)
        
        // 3. Assert - 検証
        XCTAssertNotNil(returnedLoan.returnedDate)
        XCTAssertTrue(returnedLoan.isReturned)
        
        // 貸出中リストにないことを確認
        let activeLoans = lendingModel.getActiveLoans()
        XCTAssertEqual(activeLoans.count, 0)
        
        // 履歴には残っていることを確認
        let allLoans = lendingModel.getAllLoans()
        XCTAssertEqual(allLoans.count, 1)
        XCTAssertTrue(allLoans.first?.isReturned ?? false)
    }
    
    /**
     * 存在しない貸出の返却テスト
     *
     * 存在しない貸出IDを指定して返却を試みた場合、
     * 適切なエラーが発生することを確認します。
     */
    func testReturnNonExistingLoan() throws {
        // 1. Arrange - 準備
        let nonExistingLoanId = UUID()
        
        // 2. Act & Assert - 実行と検証
        XCTAssertThrowsError(try lendingModel.returnBook(loanId: nonExistingLoanId)) { error in
            XCTAssertEqual(error as? LendingModelError, LendingModelError.loanNotFound)
        }
    }
    
    /**
     * ユーザー別貸出履歴取得機能のテスト
     *
     * 特定ユーザーの貸出履歴が正しく取得できることを確認します。
     */
    func testGetUserLoans() throws {
        // 1. Arrange - 準備
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        _ = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        
        // 2. Act - 実行
        let userLoans = lendingModel.getLoansByUser(userId: userId)
        
        // 3. Assert - 検証
        XCTAssertEqual(userLoans.count, 1)
        XCTAssertEqual(userLoans.first?.userId, userId)
    }
    
    /**
     * 書籍別貸出履歴取得機能のテスト
     *
     * 特定の絵本の貸出履歴が正しく取得できることを確認します。
     */
    func testGetBookLoanHistory() throws {
        // 1. Arrange - 準備
        let bookId = testBook.id
        let userId = testUser.id
        
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let loan = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        
        // 返却する
        _ = try lendingModel.returnBook(loanId: loan.id)
        
        // もう一度貸し出す
        _ = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
        
        // 2. Act - 実行
        let bookLoans = lendingModel.getLoansByBook(bookId: bookId)
        
        // 3. Assert - 検証
        XCTAssertEqual(bookLoans.count, 2)
        XCTAssertEqual(bookLoans.filter { $0.isReturned }.count, 1)
        XCTAssertEqual(bookLoans.filter { !$0.isReturned }.count, 1)
    }
}