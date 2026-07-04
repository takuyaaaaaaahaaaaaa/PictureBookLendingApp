import PictureBookLendingUI
import XCTest

@testable import PictureBookLendingAdmin

final class FeedbackReportMailComposerTests: XCTestCase {
    
    func testURLSchemeAndRecipient() throws {
        let url = try XCTUnwrap(
            FeedbackReportMailComposer.makeMailURL(
                type: .bug,
                detailText: "起動時にクラッシュします",
                appVersion: "1.0 (1)",
                osVersion: "iOS 26.0"
            )
        )
        
        XCTAssertEqual(url.scheme, "mailto")
        XCTAssertTrue(
            url.absoluteString.hasPrefix("mailto:\(FeedbackReportMailComposer.recipientEmail)"),
            url.absoluteString
        )
    }
    
    func testSubjectDiffersByType() throws {
        let bugURL = try XCTUnwrap(
            FeedbackReportMailComposer.makeMailURL(
                type: .bug, detailText: "詳細", appVersion: "1.0", osVersion: "iOS 26.0"))
        let requestURL = try XCTUnwrap(
            FeedbackReportMailComposer.makeMailURL(
                type: .request, detailText: "詳細", appVersion: "1.0", osVersion: "iOS 26.0"))
        
        XCTAssertNotEqual(bugURL.absoluteString, requestURL.absoluteString)
    }
    
    func testBodyContainsDetailAndVersionInfo() throws {
        let url = try XCTUnwrap(
            FeedbackReportMailComposer.makeMailURL(
                type: .other,
                detailText: "貸出画面の文字が小さいです",
                appVersion: "2.3 (45)",
                osVersion: "iOS 26.1"
            )
        )
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let body = try XCTUnwrap(components.queryItems?.first { $0.name == "body" }?.value)
        
        XCTAssertTrue(body.contains("貸出画面の文字が小さいです"))
        XCTAssertTrue(body.contains("2.3 (45)"))
        XCTAssertTrue(body.contains("iOS 26.1"))
    }
    
    func testHandlesSpecialCharactersInDetailText() throws {
        let detail = "改行あり\n記号あり & = ? # を含みます"
        
        let url = FeedbackReportMailComposer.makeMailURL(
            type: .bug, detailText: detail, appVersion: "1.0", osVersion: "iOS 26.0")
        
        XCTAssertNotNil(url)
    }
}
