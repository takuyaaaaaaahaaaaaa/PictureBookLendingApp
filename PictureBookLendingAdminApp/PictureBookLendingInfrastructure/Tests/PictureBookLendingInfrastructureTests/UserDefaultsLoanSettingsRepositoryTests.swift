import XCTest

@testable import PictureBookLendingDomain
@testable import PictureBookLendingInfrastructure

final class UserDefaultsLoanSettingsRepositoryTests: XCTestCase {
    
    var userDefaults: UserDefaults!
    var repository: UserDefaultsLoanSettingsRepository!
    
    override func setUp() {
        super.setUp()
        // テスト用のUserDefaultsを作成（テスト後に削除される）
        userDefaults = UserDefaults(suiteName: "test.PictureBookLending.LoanSettings")!
        repository = UserDefaultsLoanSettingsRepository(userDefaults: userDefaults)
    }
    
    override func tearDown() {
        // テストデータをクリーンアップ
        userDefaults.removePersistentDomain(forName: "test.PictureBookLending.LoanSettings")
        repository = nil
        userDefaults = nil
        super.tearDown()
    }
    
    func testFetchDefaultSettings() {
        // 初回取得時はデフォルト設定が返されること
        let settings = repository.fetch()
        
        XCTAssertEqual(settings, .default)
        XCTAssertEqual(settings.defaultLoanPeriodDays, 14)
    }
    
    func testSaveAndFetch() throws {
        // 設定を保存
        let newSettings = LoanSettings(defaultLoanPeriodDays: 21)
        try repository.save(newSettings)
        
        // 保存された設定を取得
        let fetchedSettings = repository.fetch()
        
        XCTAssertEqual(fetchedSettings, newSettings)
        XCTAssertEqual(fetchedSettings.defaultLoanPeriodDays, 21)
    }
    
    func testPersistence() throws {
        // 設定を保存
        let customSettings = LoanSettings(defaultLoanPeriodDays: 7)
        try repository.save(customSettings)
        
        // 新しいリポジトリインスタンスを作成
        let newRepository = UserDefaultsLoanSettingsRepository(userDefaults: userDefaults)
        
        // 設定が永続化されていることを確認
        let persistedSettings = newRepository.fetch()
        XCTAssertEqual(persistedSettings, customSettings)
        XCTAssertEqual(persistedSettings.defaultLoanPeriodDays, 7)
    }
    
    func testOverwriteSettings() throws {
        // 最初の設定を保存
        let firstSettings = LoanSettings(defaultLoanPeriodDays: 10)
        try repository.save(firstSettings)
        
        var fetchedSettings = repository.fetch()
        XCTAssertEqual(fetchedSettings.defaultLoanPeriodDays, 10)
        
        // 設定を上書き
        let secondSettings = LoanSettings(defaultLoanPeriodDays: 30)
        try repository.save(secondSettings)
        
        fetchedSettings = repository.fetch()
        XCTAssertEqual(fetchedSettings.defaultLoanPeriodDays, 30)
        XCTAssertEqual(fetchedSettings, secondSettings)
    }
    
    func testInvalidDataHandling() {
        // 無効なJSONデータをUserDefaultsに直接設定
        let invalidData = "invalid json data".data(using: .utf8)!
        userDefaults.set(invalidData, forKey: "PictureBookLending_LoanSettings")
        
        // 無効なデータの場合はデフォルト設定が返されること
        let settings = repository.fetch()
        XCTAssertEqual(settings, .default)
    }
    
    func testMissingDataHandling() {
        // データが存在しない場合
        userDefaults.removeObject(forKey: "PictureBookLending_LoanSettings")
        
        // デフォルト設定が返されること
        let settings = repository.fetch()
        XCTAssertEqual(settings, .default)
    }
    
    func testEncodingDecodingRoundTrip() throws {
        // 境界値のテスト
        let testCases = [
            LoanSettings(defaultLoanPeriodDays: 1),
            LoanSettings(defaultLoanPeriodDays: 365),
            LoanSettings(defaultLoanPeriodDays: 14),  // デフォルト値
        ]
        
        for testSettings in testCases {
            try repository.save(testSettings)
            let fetchedSettings = repository.fetch()
            XCTAssertEqual(
                fetchedSettings, testSettings,
                "Failed for settings with \(testSettings.defaultLoanPeriodDays) days")
        }
    }
}
