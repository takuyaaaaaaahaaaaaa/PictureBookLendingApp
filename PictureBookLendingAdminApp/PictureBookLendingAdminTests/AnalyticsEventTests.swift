import PictureBookLendingInfrastructure
import XCTest

@testable import PictureBookLendingAdmin

/// 利用ログのイベント語彙（`AnalyticsEvent`）のテスト
///
/// イベント名・プロパティはダッシュボードの集計キーそのものなので、
/// 意図せず変わっていないことをここで固定する（docs/ANALYTICS_DESIGN.md §3）。
final class AnalyticsEventTests: XCTestCase {
    
    // MARK: - 貸出フロー
    
    func testBorrowFlowStarted() {
        let event = AnalyticsEvent.borrowFlowStarted(findMethod: .kanaIndex)
        
        XCTAssertEqual(event.name, "borrow_flow_started")
        XCTAssertEqual(event.params, ["find_method": .string("kana_index")])
    }
    
    func testBorrowUserSelected() {
        let event = AnalyticsEvent.borrowUserSelected(elapsedMs: 1200)
        
        XCTAssertEqual(event.name, "borrow_user_selected")
        XCTAssertEqual(event.params, ["elapsed_ms": .int(1200)])
    }
    
    func testBorrowUserSelectedWithoutElapsedDropsKey() {
        let event = AnalyticsEvent.borrowUserSelected(elapsedMs: nil)
        
        XCTAssertEqual(event.params, [:])
    }
    
    func testBorrowCompleted() {
        let event = AnalyticsEvent.borrowCompleted(
            totalMs: 4200, slotType: .guardian, isGuardianFallback: true)
        
        XCTAssertEqual(event.name, "borrow_completed")
        XCTAssertEqual(
            event.params,
            [
                "total_ms": .int(4200),
                "slot_type": .string("guardian"),
                "guardian_fallback": .bool(true),
            ])
    }
    
    func testBorrowCompletedWithoutTotalDropsKey() {
        let event = AnalyticsEvent.borrowCompleted(
            totalMs: nil, slotType: .child, isGuardianFallback: false)
        
        XCTAssertEqual(
            event.params,
            [
                "slot_type": .string("child"),
                "guardian_fallback": .bool(false),
            ])
    }
    
    func testBorrowAbandoned() {
        let event = AnalyticsEvent.borrowAbandoned(
            lastStep: .slotSelection, reason: .idleTimeout, elapsedMs: 15000)
        
        XCTAssertEqual(event.name, "borrow_abandoned")
        XCTAssertEqual(
            event.params,
            [
                "last_step": .string("slot_selection"),
                "reason": .string("idle_timeout"),
                "elapsed_ms": .int(15000),
            ])
    }
    
    func testBorrowAbandonedWithoutElapsedDropsKey() {
        let event = AnalyticsEvent.borrowAbandoned(
            lastStep: .userSelection, reason: .userClosed, elapsedMs: nil)
        
        XCTAssertEqual(
            event.params,
            [
                "last_step": .string("user_selection"),
                "reason": .string("user_closed"),
            ])
    }
    
    func testBorrowBlockedNoSlot() {
        let event = AnalyticsEvent.borrowBlockedNoSlot
        
        XCTAssertEqual(event.name, "borrow_blocked_no_slot")
        XCTAssertEqual(event.params, [:])
    }
    
    // MARK: - 検索
    
    func testBookSearchPerformed() {
        let event = AnalyticsEvent.bookSearchPerformed(
            queryLength: 4, resultCount: 0, isFuzzyTriggered: true, isZeroHit: true)
        
        XCTAssertEqual(event.name, "book_search_performed")
        XCTAssertEqual(
            event.params,
            [
                "query_length": .int(4),
                "result_count": .int(0),
                "fuzzy_triggered": .bool(true),
                "zero_hit": .bool(true),
            ])
    }
    
    // MARK: - 返却フロー
    
    func testReturnFamilyOpened() {
        let event = AnalyticsEvent.returnFamilyOpened(
            findMethod: .searchBookTitle, isOverdueFilterActive: false)
        
        XCTAssertEqual(event.name, "return_family_opened")
        XCTAssertEqual(
            event.params,
            [
                "find_method": .string("search_book_title"),
                "overdue_filter_active": .bool(false),
            ])
    }
    
    func testReturnCompleted() {
        let event = AnalyticsEvent.returnCompleted(elapsedMs: 2500, wasOverdue: true)
        
        XCTAssertEqual(event.name, "return_completed")
        XCTAssertEqual(
            event.params,
            [
                "elapsed_ms": .int(2500),
                "was_overdue": .bool(true),
            ])
    }
    
    func testReturnCompletedWithoutElapsedDropsKey() {
        let event = AnalyticsEvent.returnCompleted(elapsedMs: nil, wasOverdue: false)
        
        XCTAssertEqual(event.params, ["was_overdue": .bool(false)])
    }
    
    // MARK: - つまずき・俯瞰
    
    func testUndoPerformed() {
        XCTAssertEqual(AnalyticsEvent.undoPerformed(flow: .borrow).name, "undo_performed")
        XCTAssertEqual(
            AnalyticsEvent.undoPerformed(flow: .borrow).params, ["flow": .string("borrow")])
        // 返却フローのrawValueは予約語を避けた`returning`ではなく"return"であること
        XCTAssertEqual(
            AnalyticsEvent.undoPerformed(flow: .returning).params, ["flow": .string("return")])
    }
    
    func testOverdueFilterToggled() {
        let event = AnalyticsEvent.overdueFilterToggled
        
        XCTAssertEqual(event.name, "overdue_filter_toggled")
        XCTAssertEqual(event.params, [:])
    }
    
    // MARK: - 見つけ方の語彙
    
    func testBookFindMethodRawValues() {
        XCTAssertEqual(AnalyticsEvent.BookFindMethod.search.rawValue, "search")
        XCTAssertEqual(AnalyticsEvent.BookFindMethod.kanaIndex.rawValue, "kana_index")
        XCTAssertEqual(AnalyticsEvent.BookFindMethod.shelf.rawValue, "shelf")
        XCTAssertEqual(AnalyticsEvent.BookFindMethod.scroll.rawValue, "scroll")
    }
    
    func testReturnFindMethodRawValues() {
        XCTAssertEqual(AnalyticsEvent.ReturnFindMethod.searchName.rawValue, "search_name")
        XCTAssertEqual(
            AnalyticsEvent.ReturnFindMethod.searchBookTitle.rawValue, "search_book_title")
        XCTAssertEqual(AnalyticsEvent.ReturnFindMethod.browse.rawValue, "browse")
    }
}
