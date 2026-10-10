import XCTest

@testable import PictureBookLendingUI

final class CelebrationFeedbackTests: XCTestCase {

    func testInitialState() {
        let feedback = CelebrationFeedback()

        XCTAssertFalse(feedback.isPresented)
        XCTAssertEqual(feedback.title, "")
        XCTAssertEqual(feedback.message, "")
        XCTAssertEqual(feedback.occurrenceCount, 0)
    }

    func testShowPresentsTitleAndMessage() {
        var feedback = CelebrationFeedback()

        feedback.show(title: "10回よんだよ！", message: "さくらさんおめでとう！")

        XCTAssertTrue(feedback.isPresented)
        XCTAssertEqual(feedback.title, "10回よんだよ！")
        XCTAssertEqual(feedback.message, "さくらさんおめでとう！")
        XCTAssertEqual(feedback.occurrenceCount, 1)
    }

    func testDismissHidesButKeepsContent() {
        var feedback = CelebrationFeedback()
        feedback.show(title: "10回よんだよ！", message: "さくらさんおめでとう！")

        feedback.dismiss()

        XCTAssertFalse(feedback.isPresented)
        XCTAssertEqual(feedback.title, "10回よんだよ！")
        XCTAssertEqual(feedback.message, "さくらさんおめでとう！")
        XCTAssertEqual(feedback.occurrenceCount, 1)
    }

    func testConsecutiveShowsIncrementOccurrenceCount() {
        var feedback = CelebrationFeedback()

        feedback.show(title: "10回よんだよ！", message: "さくらさんおめでとう！")
        feedback.show(title: "20冊目！", message: "はるとさんおめでとう！")

        XCTAssertTrue(feedback.isPresented)
        XCTAssertEqual(feedback.title, "20冊目！")
        XCTAssertEqual(feedback.message, "はるとさんおめでとう！")
        XCTAssertEqual(
            feedback.occurrenceCount, 2, "連続表示でもハプティクス・タイマー・紙吹雪が再発火するようカウントが増える")
    }

    func testShowAfterDismissPresentsAgain() {
        var feedback = CelebrationFeedback()
        feedback.show(title: "10回よんだよ！", message: "さくらさんおめでとう！")
        feedback.dismiss()

        feedback.show(title: "20冊目！", message: "はるとさんおめでとう！")

        XCTAssertTrue(feedback.isPresented)
        XCTAssertEqual(feedback.occurrenceCount, 2)
    }
}
