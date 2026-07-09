import PictureBookLendingDomain
import XCTest

@testable import PictureBookLendingAdmin

final class LoanFormatterTests: XCTestCase {
    
    /// 2026年6月20日（土）12:00 の Date を生成する
    ///
    /// `dueDateText` は実行環境の現在タイムゾーンで整形されるため、
    /// 期待値と日付がズレないよう現在のタイムゾーンで組み立てる
    /// （JST固定にするとCI（米国太平洋時間）で6月19日(金)に整形されて失敗する）
    private func makeDate() -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 20
        components.hour = 12
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)!
    }
    
    func testDueDateTextContainsMonthDayAndWeekday() {
        let loan = Loan(
            bookId: UUID(),
            user: User(name: "いとう さくら", classGroupId: UUID()),
            loanDate: makeDate().addingTimeInterval(-7 * 24 * 60 * 60),
            dueDate: makeDate()
        )
        
        let text = loan.dueDateText
        
        XCTAssertTrue(text.contains("6月20日"), "月日が日本語表記で含まれる: \(text)")
        XCTAssertTrue(text.contains("土"), "曜日が含まれる: \(text)")
        XCTAssertFalse(text.contains("2026"), "年は表示しない: \(text)")
    }
}
