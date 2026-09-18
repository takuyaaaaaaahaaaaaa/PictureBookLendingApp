import XCTest

@testable import PictureBookLendingInfrastructure

final class AnalyticsParamValueTests: XCTestCase {
    
    func testStringDescriptionIsRawText() {
        XCTAssertEqual(AnalyticsParamValue.string("kana_index").description, "kana_index")
    }
    
    func testIntDescriptionIsDecimalText() {
        XCTAssertEqual(AnalyticsParamValue.int(42).description, "42")
    }
    
    func testBoolDescriptionIsTrueOrFalse() {
        XCTAssertEqual(AnalyticsParamValue.bool(true).description, "true")
        XCTAssertEqual(AnalyticsParamValue.bool(false).description, "false")
    }
}
