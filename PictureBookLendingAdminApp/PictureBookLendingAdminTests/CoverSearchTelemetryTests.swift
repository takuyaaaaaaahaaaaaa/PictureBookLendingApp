import PictureBookLendingInfrastructure
import XCTest

@testable import PictureBookLendingAdmin

final class CoverSearchTelemetryTests: XCTestCase {
    func testManyFramesAndRetriesDoNotMultiplyEvents() {
        var session = CoverSearchTelemetry()
        for _ in 0..<1000 { session.didSearch() }
        XCTAssertEqual(session.showCandidates(count: 3)?.params, ["candidate_count": .int(3)])
        XCTAssertNil(session.showCandidates(count: 2))
        XCTAssertEqual(
            session.finish(selected: true)?.params,
            [
                "outcome": .string("selected"), "had_candidates": .bool(true),
                "no_candidates": .bool(false),
            ])
        XCTAssertNil(session.finish(selected: false))
        XCTAssertNil(session.showCandidates(count: 1))
        XCTAssertNil(session.fail(.camera))
    }

    func testNoCandidatesRequiresSuccessfulSearchAndEnd() {
        var untouched = CoverSearchTelemetry()
        XCTAssertEqual(untouched.finish(selected: false)?.params["no_candidates"], .bool(false))
        var searched = CoverSearchTelemetry()
        for _ in 0..<1000 { searched.didSearch() }
        XCTAssertEqual(searched.finish(selected: false)?.params["no_candidates"], .bool(true))
        XCTAssertNil(searched.finish(selected: false))
    }

    func testFailuresAreBoundedAndNeverClassifiedAsNoCandidates() {
        var session = CoverSearchTelemetry()
        session.didSearch()
        for reason in [AnalyticsEvent.CoverFailure.permission, .camera, .recognition] {
            XCTAssertEqual(session.fail(reason)?.params, ["reason": .string(reason.rawValue)])
            XCTAssertNil(session.fail(reason))
        }
        XCTAssertEqual(session.finish(selected: false)?.params["no_candidates"], .bool(false))
    }

    func testCoverAttributionUsesExistingLoanEvents() {
        XCTAssertEqual(
            AnalyticsEvent.borrowFlowStarted(findMethod: .cover).params,
            ["find_method": .string("cover")])
        let event = AnalyticsEvent.borrowCompleted(
            totalMs: nil, slotType: .child,
            isGuardianFallback: false, findMethod: .cover)
        XCTAssertEqual(event.name, "borrow_completed")
        XCTAssertEqual(
            event.params,
            [
                "find_method": .string("cover"),
                "slot_type": .string("child"), "guardian_fallback": .bool(false),
            ])
    }
}
