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
        let classGroup = ClassGroup(
            name: "1年2組", ageGroup: AgeGroup.age(5), year: 2025)
        try mockRepositoryFactory.classGroupRepository.save(classGroup)
        
        let initialBook = Book(title: "はらぺこあおむし", author: "エリック・カール", managementNumber: "あ001")
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
    
    /// 返却取り消し機能のテスト
    @Test("返却を取り消すと貸出中に戻ることのテスト")
    @MainActor
    func undoReturn() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        let bookId = testBook.id
        let userId = testUser.id
        
        // 貸出→返却
        let loan = try loanModel.lendBook(bookId: bookId, userId: userId)
        _ = try loanModel.returnBook(loanId: loan.id)
        #expect(loanModel.isBookLent(bookId: bookId) == false)
        
        // 返却を取り消す
        let restoredLoan = try loanModel.undoReturn(loanId: loan.id)
        
        // 貸出中に戻り、元の貸出情報が保持されている
        #expect(restoredLoan.id == loan.id)
        #expect(restoredLoan.returnedDate == nil)
        #expect(restoredLoan.isReturned == false)
        #expect(restoredLoan.loanDate == loan.loanDate)
        #expect(restoredLoan.dueDate == loan.dueDate)
        #expect(loanModel.isBookLent(bookId: bookId) == true)
        #expect(loanModel.getUserActiveLoans(userId: userId).count == 1)
    }
    
    @Test("未返却の貸出の返却取り消しはエラーが発生することのテスト")
    @MainActor
    func undoReturnNotReturned() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        // 貸出のみ（未返却）
        let loan = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        
        #expect(throws: LoanModelError.undoReturnFailed) {
            try loanModel.undoReturn(loanId: loan.id)
        }
    }
    
    @Test("存在しない貸出の返却取り消しはエラーが発生することのテスト")
    @MainActor
    func undoReturnLoanNotFound() throws {
        let (_, _, _, loanModel, _, _) = try createLoanModel()
        
        #expect(throws: LoanModelError.loanNotFound) {
            try loanModel.undoReturn(loanId: UUID())
        }
    }
    
    @Test("取り消しまでに同じ絵本が貸出中になっていたらエラーが発生することのテスト")
    @MainActor
    func undoReturnBookAlreadyLent() throws {
        let (mockRepositoryFactory, _, userModel, loanModel, testBook, testUser) =
            try createLoanModel()
        let bookId = testBook.id
        
        // 利用者Aに貸出→返却
        let loan = try loanModel.lendBook(bookId: bookId, userId: testUser.id)
        _ = try loanModel.returnBook(loanId: loan.id)
        
        // 別の利用者Bに同じ絵本を貸出
        let classGroup = try mockRepositoryFactory.classGroupRepository.fetchAll().first!
        let user2 = try userModel.registerUser(User(name: "鈴木花子", classGroupId: classGroup.id))
        _ = try loanModel.lendBook(bookId: bookId, userId: user2.id)
        
        // 利用者Aの返却は取り消せない
        #expect(throws: LoanModelError.bookAlreadyLent) {
            try loanModel.undoReturn(loanId: loan.id)
        }
    }
    
    // MARK: - 副作用のないアクセサ（activeLoans）
    
    /// activeLoansが返却済みを除いた貸出のみを返すことのテスト
    @Test("activeLoansが返却済みを除いた貸出のみを返すことのテスト")
    @MainActor
    func activeLoansExcludesReturnedLoans() throws {
        let (mockRepositoryFactory, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        let loan1 = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        _ = try loanModel.returnBook(loanId: loan1.id)
        
        let testBook2 = Book(title: "ぐりとぐら", author: "中川李枝子")
        let savedBook2 = try mockRepositoryFactory.bookRepository.save(testBook2)
        let loan2 = try loanModel.lendBook(bookId: savedBook2.id, userId: testUser.id)
        
        let activeLoans = loanModel.activeLoans
        
        #expect(activeLoans.count == 1)
        #expect(activeLoans.first?.id == loan2.id)
        #expect(activeLoans.allSatisfy { !$0.isReturned })
    }
    
    /// activeLoansの呼び出し前後でキャッシュ状態が変化しない（副作用がない）ことのテスト
    @Test("activeLoansの呼び出しに副作用がないことのテスト")
    @MainActor
    func activeLoansHasNoSideEffect() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        _ = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        
        let allLoansBefore = loanModel.getAllLoans()
        _ = loanModel.activeLoans
        let allLoansAfter = loanModel.getAllLoans()
        
        #expect(allLoansBefore.map(\.id) == allLoansAfter.map(\.id))
        #expect(allLoansBefore.map(\.isReturned) == allLoansAfter.map(\.isReturned))
    }
    
    /// 初回の貸出では節目に達しないことのテスト
    @Test("初回の貸出は節目に達しないテスト")
    @MainActor
    func achievedMilestonesForFirstLoan() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        let loan = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        
        #expect(loanModel.achievedMilestones(for: loan).isEmpty)
    }
    
    /// 同じ図書を5回借りると節目に達することのテスト
    @Test("同じ図書の5回目の貸出で節目に達するテスト")
    @MainActor
    func achievedMilestonesForRepeatedBook() throws {
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        // 4回借りて返す
        for _ in 1...4 {
            let loan = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
            _ = try loanModel.returnBook(loanId: loan.id)
        }
        
        // 5回目の貸出で節目に達する
        let fifthLoan = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        
        #expect(loanModel.achievedMilestones(for: fifthLoan) == [.repeatedBook(count: 5)])
    }
    
    /// 10種類目の図書を借りると節目に達することのテスト
    @Test("10種類目の図書の貸出で節目に達するテスト")
    @MainActor
    func achievedMilestonesForDistinctBooks() throws {
        let (mockRepositoryFactory, _, _, loanModel, testBook, testUser) = try createLoanModel()
        
        // 最初の図書を含めて9種類を借りて返す
        var loan = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        _ = try loanModel.returnBook(loanId: loan.id)
        for index in 2...9 {
            let book = try mockRepositoryFactory.bookRepository.save(Book(title: "図書\(index)"))
            loan = try loanModel.lendBook(bookId: book.id, userId: testUser.id)
            _ = try loanModel.returnBook(loanId: loan.id)
        }
        
        // 10種類目の貸出で節目に達する
        let tenthBook = try mockRepositoryFactory.bookRepository.save(Book(title: "図書10"))
        let tenthLoan = try loanModel.lendBook(bookId: tenthBook.id, userId: testUser.id)
        
        #expect(loanModel.achievedMilestones(for: tenthLoan) == [.distinctBooks(count: 10)])
    }
    
    // MARK: - 削除済み利用者の貸出（activeLoanBorrower）
    
    /// 利用者が削除されても貸出記録から利用者情報を取り出せることのテスト
    ///
    /// 削除済みの利用者でも家庭の枠を組み立てて返却できるようにするために使います。
    @Test("削除済み利用者でも貸出記録から利用者情報が取れることのテスト")
    @MainActor
    func activeLoanBorrowerAfterUserDeletion() throws {
        // 1. Arrange - 準備
        let (_, _, userModel, loanModel, testBook, testUser) = try createLoanModel()
        _ = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        _ = try userModel.deleteUser(testUser.id)
        
        // 2. Act - 実行
        let borrower = loanModel.activeLoanBorrower(userId: testUser.id)
        
        // 3. Assert - 検証
        #expect(userModel.findUserById(testUser.id) == nil, "利用者は削除済み")
        #expect(borrower?.name == "山田太郎", "貸出時のスナップショットから復元される")
    }
    
    /// 未返却の貸出がなければ取得できないことのテスト
    @Test("未返却の貸出がなければ利用者情報が返らないことのテスト")
    @MainActor
    func activeLoanBorrowerWithoutActiveLoan() throws {
        // 1. Arrange - 準備
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        let loan = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        _ = try loanModel.returnBook(loanId: loan.id)
        
        // 2. Act - 実行
        let borrower = loanModel.activeLoanBorrower(userId: testUser.id)
        
        // 3. Assert - 検証
        #expect(borrower == nil)
    }
    
    // MARK: - 貸出のまとめ返却（returnLoans）
    
    /// 複数の貸出をまとめて返却できることのテスト
    ///
    /// 利用者の削除（個別・進級・端末初期化）に先立つ自動返却で使います。
    @Test("複数の貸出をまとめて返却できることのテスト")
    @MainActor
    func returnLoansReturnsAllGivenLoans() throws {
        // 1. Arrange - 準備
        let (mockRepositoryFactory, _, _, loanModel, testBook, testUser) = try createLoanModel()
        try mockRepositoryFactory.loanSettingsRepository.save(
            LoanSettings(defaultLoanPeriodDays: 14, maxBooksPerUser: 2))
        let anotherBook = try mockRepositoryFactory.bookRepository.save(Book(title: "ぐりとぐら"))
        _ = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        _ = try loanModel.lendBook(bookId: anotherBook.id, userId: testUser.id)
        
        // 2. Act - 実行
        let returnedCount = try loanModel.returnLoans(loanModel.activeLoans)
        
        // 3. Assert - 検証
        #expect(returnedCount == 2)
        #expect(loanModel.activeLoans.isEmpty)
        #expect(loanModel.isBookLent(bookId: testBook.id) == false, "図書が棚に戻る")
        #expect(loanModel.isBookLent(bookId: anotherBook.id) == false)
    }
    
    /// 返却対象がなければ0件になることのテスト
    @Test("返却対象がなければ0冊を返すことのテスト")
    @MainActor
    func returnLoansWithEmptyInput() throws {
        // 1. Arrange - 準備
        let (_, _, _, loanModel, _, _) = try createLoanModel()
        
        // 2. Act - 実行
        let returnedCount = try loanModel.returnLoans([])
        
        // 3. Assert - 検証
        #expect(returnedCount == 0)
    }
    
    // MARK: - 図書ごとの未返却の貸出（getBookActiveLoans）
    
    /// 貸出中の図書の未返却の貸出が取得できることのテスト
    ///
    /// 図書を削除する前に自動返却する対象を洗い出すために使います。
    @Test("貸出中の図書の未返却の貸出が取得できることのテスト")
    @MainActor
    func getBookActiveLoansWhileLent() throws {
        // 1. Arrange - 準備
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        let loan = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        
        // 2. Act - 実行
        let activeLoans = loanModel.getBookActiveLoans(bookId: testBook.id)
        
        // 3. Assert - 検証
        #expect(activeLoans.map(\.id) == [loan.id])
    }
    
    /// 返却済みの貸出は含まれないことのテスト
    @Test("返却済みの貸出は図書の未返却の貸出に含まれないことのテスト")
    @MainActor
    func getBookActiveLoansExcludesReturnedLoan() throws {
        // 1. Arrange - 準備
        let (_, _, _, loanModel, testBook, testUser) = try createLoanModel()
        let loan = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        _ = try loanModel.returnBook(loanId: loan.id)
        
        // 2. Act - 実行
        let activeLoans = loanModel.getBookActiveLoans(bookId: testBook.id)
        
        // 3. Assert - 検証
        #expect(activeLoans.isEmpty)
    }
    
    /// 他の図書の貸出が混ざらないことのテスト
    @Test("他の図書の貸出が混ざらないことのテスト")
    @MainActor
    func getBookActiveLoansIsScopedToBook() throws {
        // 1. Arrange - 準備
        let (mockRepositoryFactory, _, _, loanModel, testBook, testUser) = try createLoanModel()
        let anotherBook = try mockRepositoryFactory.bookRepository.save(Book(title: "ぐりとぐら"))
        let anotherUser = try mockRepositoryFactory.userRepository.save(
            User(name: "鈴木花子", classGroupId: testUser.classGroupId))
        _ = try loanModel.lendBook(bookId: testBook.id, userId: testUser.id)
        let anotherLoan = try loanModel.lendBook(bookId: anotherBook.id, userId: anotherUser.id)
        
        // 2. Act - 実行
        let activeLoans = loanModel.getBookActiveLoans(bookId: anotherBook.id)
        
        // 3. Assert - 検証
        #expect(activeLoans.map(\.id) == [anotherLoan.id])
    }
}
