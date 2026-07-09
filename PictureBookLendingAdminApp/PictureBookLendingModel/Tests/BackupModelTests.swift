import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingModel

/// BackupModelテストケース
///
/// バックアップのエクスポート/インポート機能をテストするためのケース集です。
@Suite("BackupModel Tests")
struct BackupModelTests {
    
    @MainActor
    private func createBackupModel() -> (
        model: BackupModel,
        bookRepository: MockBookRepository,
        userRepository: MockUserRepository,
        classGroupRepository: MockClassGroupRepository,
        loanRepository: MockLoanRepository,
        loanSettingsRepository: MockLoanSettingsRepository,
        imageStorageRepository: MockImageStorageRepository
    ) {
        let bookRepository = MockBookRepository()
        let userRepository = MockUserRepository()
        let classGroupRepository = MockClassGroupRepository()
        let loanRepository = MockLoanRepository()
        let loanSettingsRepository = MockLoanSettingsRepository()
        let imageStorageRepository = MockImageStorageRepository()
        
        let model = BackupModel(
            bookRepository: bookRepository,
            userRepository: userRepository,
            classGroupRepository: classGroupRepository,
            loanRepository: loanRepository,
            loanSettingsRepository: loanSettingsRepository,
            imageStorageRepository: imageStorageRepository
        )
        
        return (
            model, bookRepository, userRepository, classGroupRepository, loanRepository,
            loanSettingsRepository, imageStorageRepository
        )
    }
    
    /// スナップショット作成機能のテスト
    ///
    /// 各リポジトリのデータと画像がスナップショットにまとめられることを確認します。
    @Test("スナップショット作成機能")
    @MainActor
    func createSnapshot() throws {
        // 1. Arrange - 準備
        let (
            model, bookRepository, userRepository, classGroupRepository, loanRepository,
            loanSettingsRepository, imageStorageRepository
        ) = createBackupModel()
        
        let classGroup = ClassGroup(name: "ひよこ組", ageGroup: .age(3), year: 2026)
        try classGroupRepository.save(classGroup)
        
        let user = try userRepository.save(
            User(name: "たろう", classGroupId: classGroup.id, userType: .child))
        
        var book = Book(title: "はらぺこあおむし", author: "エリック・カール", managementNumber: "あ001")
        book.localImageFileName = "cover.jpg"
        _ = try bookRepository.save(book)
        try imageStorageRepository.saveImageData(Data([0x01, 0x02]), fileName: "cover.jpg")
        
        _ = try loanRepository.save(
            Loan(bookId: book.id, user: user, loanDate: Date(), dueDate: Date()))
        
        try loanSettingsRepository.save(LoanSettings(defaultLoanPeriodDays: 10, maxBooksPerUser: 2))
        
        // 2. Act - 実行
        let snapshot = try model.createSnapshot()
        
        // 3. Assert - 検証
        #expect(snapshot.schemaVersion == BackupSnapshot.currentSchemaVersion)
        #expect(snapshot.classGroups == [classGroup])
        #expect(snapshot.users == [user])
        #expect(snapshot.books.count == 1)
        #expect(snapshot.loans.count == 1)
        #expect(snapshot.loanSettings.defaultLoanPeriodDays == 10)
        #expect(snapshot.bookImages["cover.jpg"] == Data([0x01, 0x02]))
    }
    
    /// 復元機能のテスト
    ///
    /// スナップショットから全データが復元され、既存データが置き換わることを確認します。
    @Test("復元機能：既存データが置き換わる")
    @MainActor
    func restoreReplacesExistingData() throws {
        // 1. Arrange - 準備
        let (
            model, bookRepository, userRepository, classGroupRepository, loanRepository,
            loanSettingsRepository, imageStorageRepository
        ) = createBackupModel()
        
        // 復元前に既存データを投入
        let staleClassGroup = ClassGroup(name: "旧組", ageGroup: .age(1), year: 2025)
        try classGroupRepository.save(staleClassGroup)
        _ = try bookRepository.save(Book(title: "古い本", managementNumber: "旧001"))
        
        // 復元対象のスナップショットを構築
        let classGroup = ClassGroup(name: "ひよこ組", ageGroup: .age(3), year: 2026)
        let user = User(name: "たろう", classGroupId: classGroup.id, userType: .child)
        var book = Book(title: "はらぺこあおむし", author: "エリック・カール", managementNumber: "あ001")
        book.localImageFileName = "cover.jpg"
        let loan = Loan(bookId: book.id, user: user, loanDate: Date(), dueDate: Date())
        let snapshot = BackupSnapshot(
            createdAt: Date(),
            classGroups: [classGroup],
            users: [user],
            books: [book],
            loans: [loan],
            loanSettings: LoanSettings(defaultLoanPeriodDays: 21, maxBooksPerUser: 3),
            bookImages: ["cover.jpg": Data([0x09, 0x08])]
        )
        
        // 2. Act - 実行
        let summary = try model.restore(from: snapshot)
        
        // 3. Assert - 検証
        #expect(summary.classGroupCount == 1)
        #expect(summary.userCount == 1)
        #expect(summary.bookCount == 1)
        #expect(summary.loanCount == 1)
        
        #expect(try classGroupRepository.fetchAll() == [classGroup])
        #expect(try userRepository.fetchAll() == [user])
        #expect(try bookRepository.fetchAll() == [book])
        #expect(try loanRepository.fetchAll().count == 1)
        #expect(loanSettingsRepository.fetch().defaultLoanPeriodDays == 21)
        #expect(imageStorageRepository.loadImageData(fileName: "cover.jpg") == Data([0x09, 0x08]))
    }
    
    /// 非対応スキーマバージョンのテスト
    ///
    /// 現在のアプリより新しいバージョンのバックアップは復元できないことを確認します。
    @Test("非対応スキーマバージョンは復元エラーになる")
    @MainActor
    func restoreRejectsFutureSchemaVersion() throws {
        // 1. Arrange - 準備
        let (model, _, _, _, _, _, _) = createBackupModel()
        let snapshot = BackupSnapshot(
            schemaVersion: BackupSnapshot.currentSchemaVersion + 1,
            createdAt: Date(),
            classGroups: [],
            users: [],
            books: [],
            loans: [],
            loanSettings: .default,
            bookImages: [:]
        )
        
        // 2. Act & Assert - 実行と検証
        #expect(throws: BackupModelError.self) {
            try model.restore(from: snapshot)
        }
    }
    
    /// 復元途中で失敗した場合のロールバックのテスト
    ///
    /// スナップショット投入中にエラーが起きても、復元前の状態に戻ることを確認します。
    @Test("復元が途中で失敗した場合は元の状態にロールバックされる")
    @MainActor
    func restoreRollsBackOnFailure() throws {
        // 1. Arrange - 準備
        let (
            model, bookRepository, userRepository, classGroupRepository, loanRepository,
            loanSettingsRepository, _
        ) = createBackupModel()
        
        // 復元前の既存データ
        let staleClassGroup = ClassGroup(name: "旧組", ageGroup: .age(1), year: 2025)
        try classGroupRepository.save(staleClassGroup)
        let staleBook = try bookRepository.save(Book(title: "古い本", managementNumber: "旧001"))
        try loanSettingsRepository.save(LoanSettings(defaultLoanPeriodDays: 5, maxBooksPerUser: 1))
        
        // 同一IDの図書を2件含め、2件目の保存で失敗させることで途中失敗を再現する
        let duplicatedBook = Book(title: "重複本", managementNumber: "重複001")
        let snapshot = BackupSnapshot(
            createdAt: Date(),
            classGroups: [],
            users: [],
            books: [duplicatedBook, duplicatedBook],
            loans: [],
            loanSettings: LoanSettings(defaultLoanPeriodDays: 30, maxBooksPerUser: 5),
            bookImages: [:]
        )
        
        // 2. Act - 実行
        #expect(throws: BackupModelError.self) {
            try model.restore(from: snapshot)
        }
        
        // 3. Assert - 検証（復元前の状態に戻っていること）
        #expect(try classGroupRepository.fetchAll() == [staleClassGroup])
        #expect(try bookRepository.fetchAll() == [staleBook])
        #expect(try userRepository.fetchAll().isEmpty)
        #expect(try loanRepository.fetchAll().isEmpty)
        #expect(loanSettingsRepository.fetch().defaultLoanPeriodDays == 5)
    }
}
