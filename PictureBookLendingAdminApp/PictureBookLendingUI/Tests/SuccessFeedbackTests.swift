import XCTest

@testable import PictureBookLendingUI

final class SuccessFeedbackTests: XCTestCase {
    
    func testInitialState() {
        let feedback = SuccessFeedback()
        
        XCTAssertFalse(feedback.isPresented)
        XCTAssertEqual(feedback.message, "")
        XCTAssertEqual(feedback.occurrenceCount, 0)
    }
    
    func testShowPresentsMessage() {
        var feedback = SuccessFeedback()
        
        feedback.show("返却しました")
        
        XCTAssertTrue(feedback.isPresented)
        XCTAssertEqual(feedback.message, "返却しました")
        XCTAssertEqual(feedback.occurrenceCount, 1)
    }
    
    func testDismissHidesButKeepsMessage() {
        var feedback = SuccessFeedback()
        feedback.show("返却しました")
        
        feedback.dismiss()
        
        XCTAssertFalse(feedback.isPresented)
        XCTAssertEqual(feedback.message, "返却しました")
        XCTAssertEqual(feedback.occurrenceCount, 1)
    }
    
    func testConsecutiveShowsIncrementOccurrenceCount() {
        var feedback = SuccessFeedback()
        
        feedback.show("山田太郎さんに貸出しました")
        feedback.show("鈴木花子さんに貸出しました")
        
        XCTAssertTrue(feedback.isPresented)
        XCTAssertEqual(feedback.message, "鈴木花子さんに貸出しました")
        XCTAssertEqual(feedback.occurrenceCount, 2, "連続表示でもハプティクスとタイマーが再発火するようカウントが増える")
    }
    
    func testShowAfterDismissPresentsAgain() {
        var feedback = SuccessFeedback()
        feedback.show("返却しました")
        feedback.dismiss()
        
        feedback.show("山田太郎さんに貸出しました")
        
        XCTAssertTrue(feedback.isPresented)
        XCTAssertEqual(feedback.occurrenceCount, 2)
    }
}
