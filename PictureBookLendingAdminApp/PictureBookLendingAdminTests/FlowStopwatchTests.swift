import XCTest

@testable import PictureBookLendingAdmin

/// フロー所要時間の計測（`FlowStopwatch`）のテスト
final class FlowStopwatchTests: XCTestCase {
    
    /// 計測の基準時刻（現在時刻に依存させないため固定値を渡す）
    private let startedAt = Date(timeIntervalSince1970: 1_000_000)
    
    func testElapsedMsIsMillisecondsFromStart() {
        let stopwatch = FlowStopwatch(startedAt: startedAt)
        
        XCTAssertEqual(stopwatch.elapsedMs(at: startedAt.addingTimeInterval(4.5)), 4500)
    }
    
    func testElapsedMsIsZeroAtStart() {
        let stopwatch = FlowStopwatch(startedAt: startedAt)
        
        XCTAssertEqual(stopwatch.elapsedMs(at: startedAt), 0)
    }
    
    func testElapsedMsTruncatesSubMillisecond() {
        let stopwatch = FlowStopwatch(startedAt: startedAt)
        
        XCTAssertEqual(stopwatch.elapsedMs(at: startedAt.addingTimeInterval(0.0005)), 0)
    }
    
    func testElapsedMsIsNilAfterInvalidate() {
        var stopwatch = FlowStopwatch(startedAt: startedAt)
        
        stopwatch.invalidate()
        
        XCTAssertNil(stopwatch.elapsedMs(at: startedAt.addingTimeInterval(4.5)))
    }
    
    func testInvalidateIsNotRecoverable() {
        var stopwatch = FlowStopwatch(startedAt: startedAt)
        
        stopwatch.invalidate()
        stopwatch.invalidate()
        
        XCTAssertNil(stopwatch.elapsedMs(at: startedAt.addingTimeInterval(10)))
    }
}
