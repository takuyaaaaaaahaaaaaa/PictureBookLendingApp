import XCTest

@testable import PictureBookLendingAdmin

final class BookDeletionMessageTests: XCTestCase {
    
    func testSingleBookWithoutLoan() {
        let message = BookDeletionMessage.make(
            targetTitles: ["ぐりとぐら"],
            autoReturningLoans: []
        )
        
        XCTAssertEqual(message, "『ぐりとぐら』を削除しますか？")
    }
    
    func testMultipleBooksAreListedWithBrackets() {
        let message = BookDeletionMessage.make(
            targetTitles: ["ぐりとぐら", "はらぺこあおむし"],
            autoReturningLoans: []
        )
        
        XCTAssertEqual(message, "『ぐりとぐら』、『はらぺこあおむし』を削除しますか？")
    }
    
    func testAutoReturningLoansAreListedWithCountAndBorrower() {
        let message = BookDeletionMessage.make(
            targetTitles: ["ぐりとぐら", "はらぺこあおむし"],
            autoReturningLoans: [
                .init(bookTitle: "ぐりとぐら", userName: "山田太郎"),
                .init(bookTitle: "はらぺこあおむし", userName: "鈴木花子"),
            ]
        )
        
        XCTAssertTrue(message.contains("貸出中の図書が2冊あります。削除すると自動的に返却されます。"))
        XCTAssertTrue(message.contains("・『ぐりとぐら』（山田太郎さん）"))
        XCTAssertTrue(message.contains("・『はらぺこあおむし』（鈴木花子さん）"))
    }
    
    /// 貸出がない場合に自動返却の案内を出さないことの確認
    ///
    /// 「自動的に返却されます」は起きることの予告なので、
    /// 何も起きないときに出すと不要な不安を与えるため
    func testNoLoanNoticeWhenNothingIsLent() {
        let message = BookDeletionMessage.make(
            targetTitles: ["ぐりとぐら"],
            autoReturningLoans: []
        )
        
        XCTAssertFalse(message.contains("自動的に返却されます"))
    }
}
