import XCTest

@testable import PictureBookLendingDomain

final class LoanSettingsTests: XCTestCase {
    
    func testDefaultSettings() {
        // デフォルト設定のテスト
        let defaultSettings = LoanSettings.default
        
        XCTAssertEqual(defaultSettings.defaultLoanPeriodDays, 14)
        XCTAssertTrue(defaultSettings.isValid())
    }
    
    func testValidation() {
        // 有効な設定
        let validSettings = LoanSettings(defaultLoanPeriodDays: 7)
        XCTAssertTrue(validSettings.isValid())
        
        let validSettings2 = LoanSettings(defaultLoanPeriodDays: 30)
        XCTAssertTrue(validSettings2.isValid())
        
        let validSettings3 = LoanSettings(defaultLoanPeriodDays: 365)
        XCTAssertTrue(validSettings3.isValid())
        
        // 無効な設定
        let invalidSettings1 = LoanSettings(defaultLoanPeriodDays: 0)
        XCTAssertFalse(invalidSettings1.isValid())
        
        let invalidSettings2 = LoanSettings(defaultLoanPeriodDays: -1)
        XCTAssertFalse(invalidSettings2.isValid())
        
        let invalidSettings3 = LoanSettings(defaultLoanPeriodDays: 366)
        XCTAssertFalse(invalidSettings3.isValid())
    }
    
    func testCalculateDueDate() {
        let settings = LoanSettings(defaultLoanPeriodDays: 14)
        
        // 基準日
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        
        // 返却期限の計算
        let dueDate = settings.calculateDueDate(from: baseDate)
        let expectedDate = calendar.date(byAdding: .day, value: 14, to: baseDate)!
        
        XCTAssertEqual(dueDate, expectedDate)
    }
    
    func testCalculateDueDateWithDifferentPeriods() {
        // 7日間
        let settings7 = LoanSettings(defaultLoanPeriodDays: 7)
        let baseDate = Date()
        let dueDate7 = settings7.calculateDueDate(from: baseDate)
        let expected7 = Calendar.current.date(byAdding: .day, value: 7, to: baseDate)!
        XCTAssertEqual(dueDate7, expected7)
        
        // 30日間
        let settings30 = LoanSettings(defaultLoanPeriodDays: 30)
        let dueDate30 = settings30.calculateDueDate(from: baseDate)
        let expected30 = Calendar.current.date(byAdding: .day, value: 30, to: baseDate)!
        XCTAssertEqual(dueDate30, expected30)
    }
    
    func testEquatable() {
        let settings1 = LoanSettings(defaultLoanPeriodDays: 14)
        let settings2 = LoanSettings(defaultLoanPeriodDays: 14)
        let settings3 = LoanSettings(defaultLoanPeriodDays: 7)
        
        XCTAssertEqual(settings1, settings2)
        XCTAssertNotEqual(settings1, settings3)
    }
    
    func testCodable() throws {
        let originalSettings = LoanSettings(defaultLoanPeriodDays: 21)
        
        // エンコード
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSettings)
        
        // デコード
        let decoder = JSONDecoder()
        let decodedSettings = try decoder.decode(LoanSettings.self, from: data)
        
        XCTAssertEqual(originalSettings, decodedSettings)
    }
}
