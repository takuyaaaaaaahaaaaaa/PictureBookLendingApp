import Foundation
import XCTest

@testable import PictureBookLendingUI

final class UndoFeedbackTests: XCTestCase {
    
    func testInitialState() {
        let feedback = UndoFeedback()
        
        XCTAssertFalse(feedback.isPresented)
        XCTAssertEqual(feedback.message, "")
        XCTAssertNil(feedback.targetId)
        XCTAssertEqual(feedback.occurrenceCount, 0)
    }
    
    func testShowPresentsMessageAndTarget() {
        var feedback = UndoFeedback()
        let loanId = UUID()
        
        feedback.show("『はらぺこあおむし』を返却しました", targetId: loanId)
        
        XCTAssertTrue(feedback.isPresented)
        XCTAssertEqual(feedback.message, "『はらぺこあおむし』を返却しました")
        XCTAssertEqual(feedback.targetId, loanId)
        XCTAssertEqual(feedback.occurrenceCount, 1)
    }
    
    func testDismissHidesButKeepsTarget() {
        var feedback = UndoFeedback()
        let loanId = UUID()
        feedback.show("『はらぺこあおむし』を返却しました", targetId: loanId)
        
        feedback.dismiss()
        
        XCTAssertFalse(feedback.isPresented)
        XCTAssertEqual(feedback.targetId, loanId, "dismiss直後のonUndoでも対象を識別できるよう保持する")
    }
    
    func testConsecutiveShowsUpdateTargetAndCount() {
        var feedback = UndoFeedback()
        let firstLoanId = UUID()
        let secondLoanId = UUID()
        
        feedback.show("『はらぺこあおむし』を返却しました", targetId: firstLoanId)
        feedback.show("『ぐりとぐら』を返却しました", targetId: secondLoanId)
        
        XCTAssertTrue(feedback.isPresented)
        XCTAssertEqual(feedback.targetId, secondLoanId, "取り消し対象は常に最後の操作")
        XCTAssertEqual(feedback.occurrenceCount, 2, "連続表示でもハプティクスとタイマーが再発火するようカウントが増える")
    }
}
