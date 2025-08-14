import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingModel

/// LoanModelテストケース
///
/// 絵本の貸出・返却を管理するモデルの基本機能をテストします。
@Suite("LoanModel Tests")
struct LoanModelTests {
    
    @MainActor
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
        // まずクラスグループを作成
        let classGroup = ClassGroup(name: "1年2組", ageGroup: "6歳児", year: 2025)
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
    @MainActor
    func lendBook() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        let bookId = testBook.id
        let userId = testUser.id
        
        let loan = try loanModel.lendBook(bookId: bookId, userId: userId)
        
        #expect(loan.bookId == bookId)
        #expect(loan.user.id == userId)
        #expect(loan.dueDate > Date())
        #expect(loan.returnedDate == nil)
        #expect(loan.isReturned == false)
        
        let activeLoans = loanModel.getActiveLoans()
        #expect(activeLoans.count == 1)
        #expect(activeLoans.first?.bookId == bookId)
    }
    
    /// 絵本返却機能のテスト
    @Test("絵本返却機能のテスト")
    @MainActor
    func returnBook() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        let bookId = testBook.id
        let userId = testUser.id
        
        let loan = try loanModel.lendBook(bookId: bookId, userId: userId)
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
    @MainActor
    func returnBookByBookId() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        let bookId = testBook.id
        let userId = testUser.id
        
        let loan = try loanModel.lendBook(bookId: bookId, userId: userId)
        
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
    @MainActor
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
    
    /// 貸出可能上限チェック機能のテスト
    @Test("貸出可能上限チェック機能のテスト")
    @MainActor
    func maxBooksPerUserCheck() throws {
        let (mockRepositoryFactory, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        // 貸出可能数を1冊に設定
        let settings = LoanSettings(defaultLoanPeriodDays: 14, maxBooksPerUser: 1)
        try mockRepositoryFactory.loanSettingsRepository.save(settings)
        
        let bookId = testBook.id
        let userId = testUser.id
        
        // 1冊目の貸出（成功すべき）
        let loan1 = try loanModel.lendBook(bookId: bookId, userId: userId)
        
        #expect(loan1.user.id == userId)
        #expect(loanModel.getUserActiveLoans(userId: userId).count == 1)
        
        // 2冊目の絵本を追加
        let testBook2 = Book(title: "ぐりとぐら", author: "中川李枝子")
        let savedBook2 = try mockRepositoryFactory.bookRepository.save(testBook2)
        
        // 2冊目の貸出（上限超過でエラーになるべき）
        #expect(throws: LoanModelError.maxBooksPerUserExceeded) {
            try loanModel.lendBook(bookId: savedBook2.id, userId: userId)
        }
        
        // アクティブな貸出は1冊のまま
        #expect(loanModel.getUserActiveLoans(userId: userId).count == 1)
    }
    
    /// 返却後の再貸出テスト
    @Test("返却後の再貸出テスト")
    @MainActor
    func lendAfterReturn() throws {
        let (mockRepositoryFactory, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        // 貸出可能数を1冊に設定
        let settings = LoanSettings(defaultLoanPeriodDays: 14, maxBooksPerUser: 1)
        try mockRepositoryFactory.loanSettingsRepository.save(settings)
        
        let bookId = testBook.id
        let userId = testUser.id
        
        // 1冊目の貸出
        let loan1 = try loanModel.lendBook(bookId: bookId, userId: userId)
        
        #expect(loanModel.getUserActiveLoans(userId: userId).count == 1)
        
        // 返却
        let returnedLoan = try loanModel.returnBook(loanId: loan1.id)
        #expect(returnedLoan.isReturned == true)
        #expect(loanModel.getUserActiveLoans(userId: userId).count == 0)
        
        // 2冊目の絵本を追加
        let testBook2 = Book(title: "ぐりとぐら", author: "中川李枝子")
        let savedBook2 = try mockRepositoryFactory.bookRepository.save(testBook2)
        
        // 返却後は再度貸出可能
        let loan2 = try loanModel.lendBook(bookId: savedBook2.id, userId: userId)
        #expect(loan2.user.id == userId)
        #expect(loanModel.getUserActiveLoans(userId: userId).count == 1)
    }
    
    /// LoanがUser情報を含むことのテスト
    @Test("LoanがUser情報を含むことのテスト")
    @MainActor
    func loanContainsUserInfo() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        let bookId = testBook.id
        let userId = testUser.id
        
        let loan = try loanModel.lendBook(bookId: bookId, userId: userId)
        
        // LoanがUser情報を含むことを確認
        #expect(loan.user.id == testUser.id)
        #expect(loan.user.name == testUser.name)
        #expect(loan.user.classGroupId == testUser.classGroupId)
        
        // 後方互換性の確認
        #expect(loan.user.id == testUser.id)
    }
    
    /// getCurrentLoanメソッドのテスト
    @Test("getCurrentLoanメソッドのテスト")
    @MainActor
    func getCurrentLoan() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        let bookId = testBook.id
        let userId = testUser.id
        
        // 貸出前は現在の貸出がないことを確認
        let currentLoanBefore = loanModel.getCurrentLoan(bookId: bookId)
        #expect(currentLoanBefore == nil)
        
        // 貸出実行
        let loan = try loanModel.lendBook(bookId: bookId, userId: userId)
        
        // 貸出後は現在の貸出が取得できることを確認
        let currentLoanAfter = loanModel.getCurrentLoan(bookId: bookId)
        #expect(currentLoanAfter != nil)
        #expect(currentLoanAfter?.id == loan.id)
        #expect(currentLoanAfter?.user.name == testUser.name)
        
        // 返却実行
        let returnedLoan = try loanModel.returnBook(loanId: loan.id)
        #expect(returnedLoan.isReturned == true)
        
        // 返却後は現在の貸出がないことを確認
        let currentLoanAfterReturn = loanModel.getCurrentLoan(bookId: bookId)
        #expect(currentLoanAfterReturn == nil)
    }
    
    /// 複数冊貸出可能設定のテスト
    @Test("複数冊貸出可能設定のテスト")
    @MainActor
    func multipleBooksAllowed() throws {
        let (mockRepositoryFactory, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        // 貸出可能数を3冊に設定
        let settings = LoanSettings(defaultLoanPeriodDays: 14, maxBooksPerUser: 3)
        try mockRepositoryFactory.loanSettingsRepository.save(settings)
        
        let userId = testUser.id
        
        // 1冊目の貸出
        _ = try loanModel.lendBook(bookId: testBook.id, userId: userId)
        #expect(loanModel.getUserActiveLoans(userId: userId).count == 1)
        
        // 2冊目の絵本を追加
        let testBook2 = Book(title: "ぐりとぐら", author: "中川李枝子")
        let savedBook2 = try mockRepositoryFactory.bookRepository.save(testBook2)
        
        // 2冊目の貸出
        _ = try loanModel.lendBook(bookId: savedBook2.id, userId: userId)
        #expect(loanModel.getUserActiveLoans(userId: userId).count == 2)
        
        // 3冊目の絵本を追加
        let testBook3 = Book(title: "からすのパンやさん", author: "かこさとし")
        let savedBook3 = try mockRepositoryFactory.bookRepository.save(testBook3)
        
        // 3冊目の貸出
        _ = try loanModel.lendBook(bookId: savedBook3.id, userId: userId)
        #expect(loanModel.getUserActiveLoans(userId: userId).count == 3)
        
        // 4冊目の絵本を追加
        let testBook4 = Book(title: "14ひきのあさごはん", author: "いわむらかずお")
        let savedBook4 = try mockRepositoryFactory.bookRepository.save(testBook4)
        
        // 4冊目の貸出（上限超過でエラーになるべき）
        #expect(throws: LoanModelError.maxBooksPerUserExceeded) {
            try loanModel.lendBook(bookId: savedBook4.id, userId: userId)
        }
        
        // アクティブな貸出は3冊のまま
        #expect(loanModel.getUserActiveLoans(userId: userId).count == 3)
    }
}
