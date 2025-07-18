import XCTest

@testable import PictureBookLendingDomain
@testable import PictureBookLendingModel

final class LoanSettingsModelTests: XCTestCase {
    
    fileprivate var mockRepository: MockLoanSettingsRepository!
    var model: LoanSettingsModel!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockLoanSettingsRepository()
        model = LoanSettingsModel(repository: mockRepository)
    }
    
    override func tearDown() {
        model = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testInitialSettings() {
        // 初期設定がデフォルト値になっていることを確認
        XCTAssertEqual(model.settings, .default)
        XCTAssertEqual(model.settings.defaultLoanPeriodDays, 14)
    }
    
    func testUpdateValidSettings() throws {
        // 有効な設定値で更新
        let newSettings = LoanSettings(defaultLoanPeriodDays: 7)
        
        try model.updateSettings(newSettings)
        
        // モデルの設定が更新されていることを確認
        XCTAssertEqual(model.settings, newSettings)
        XCTAssertEqual(model.settings.defaultLoanPeriodDays, 7)
        
        // リポジトリに保存されていることを確認
        XCTAssertEqual(mockRepository.fetch(), newSettings)
    }
    
    func testUpdateInvalidSettings() {
        // 無効な設定値で更新を試行
        let invalidSettings = LoanSettings(defaultLoanPeriodDays: 0)
        
        XCTAssertThrowsError(try model.updateSettings(invalidSettings)) { error in
            XCTAssertEqual(error as? LoanSettingsError, .invalidSettings)
        }
        
        // モデルの設定が変更されていないことを確認
        XCTAssertEqual(model.settings, .default)
    }
    
    func testResetToDefault() throws {
        // 設定を変更
        let customSettings = LoanSettings(defaultLoanPeriodDays: 30)
        try model.updateSettings(customSettings)
        XCTAssertEqual(model.settings.defaultLoanPeriodDays, 30)
        
        // デフォルトにリセット
        try model.resetToDefault()
        
        // デフォルト設定に戻っていることを確認
        XCTAssertEqual(model.settings, .default)
        XCTAssertEqual(model.settings.defaultLoanPeriodDays, 14)
        
        // リポジトリにも保存されていることを確認
        XCTAssertEqual(mockRepository.fetch(), LoanSettings.default)
    }
    
    func testRepositoryError() {
        // エラーを投げるモックリポジトリを作成
        let errorRepository = ErrorThrowingMockLoanSettingsRepository()
        let errorModel = LoanSettingsModel(repository: errorRepository)
        
        let newSettings = LoanSettings(defaultLoanPeriodDays: 21)
        
        // リポジトリエラーが伝播することを確認
        XCTAssertThrowsError(try errorModel.updateSettings(newSettings))
        
        // 設定が変更されていないことを確認
        XCTAssertEqual(errorModel.settings, .default)
    }
}

// MARK: - Test Helpers

private final class ErrorThrowingMockLoanSettingsRepository: LoanSettingsRepositoryProtocol,
    @unchecked Sendable
{
    func fetch() -> LoanSettings {
        return .default
    }
    
    func save(_ settings: LoanSettings) throws {
        throw NSError(
            domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
    }
}

private final class MockLoanSettingsRepository: LoanSettingsRepositoryProtocol, @unchecked Sendable
{
    private let lock = NSLock()
    private var _settings: LoanSettings = .default
    
    func fetch() -> LoanSettings {
        lock.lock()
        defer { lock.unlock() }
        return _settings
    }
    
    func save(_ newSettings: LoanSettings) throws {
        lock.lock()
        defer { lock.unlock() }
        _settings = newSettings
    }
}
