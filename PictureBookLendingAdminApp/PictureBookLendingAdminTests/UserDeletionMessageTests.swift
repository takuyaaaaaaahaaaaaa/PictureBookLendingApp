import XCTest

@testable import PictureBookLendingAdmin

final class UserDeletionMessageTests: XCTestCase {
    
    func testSingleUserWithoutGuardianOrLoan() {
        let message = UserDeletionMessage.make(
            targetNames: ["山田太郎"],
            cascadedGuardianNames: [],
            autoReturningLoans: []
        )
        
        XCTAssertEqual(message, "山田太郎さんを削除しますか？")
    }
    
    func testMultipleUsersAreListedWithHonorific() {
        let message = UserDeletionMessage.make(
            targetNames: ["山田太郎", "鈴木花子"],
            cascadedGuardianNames: [],
            autoReturningLoans: []
        )
        
        XCTAssertEqual(message, "山田太郎さん、鈴木花子さんを削除しますか？")
    }
    
    func testCascadedGuardiansAreAnnounced() {
        let message = UserDeletionMessage.make(
            targetNames: ["山田太郎"],
            cascadedGuardianNames: ["山田花子", "山田一郎"],
            autoReturningLoans: []
        )
        
        XCTAssertTrue(message.contains("関連する保護者（山田花子さん、山田一郎さん）も合わせて削除されます。"))
    }
    
    func testAutoReturningLoansAreListedWithCount() {
        let message = UserDeletionMessage.make(
            targetNames: ["山田太郎"],
            cascadedGuardianNames: [],
            autoReturningLoans: [
                .init(userName: "山田太郎", bookTitle: "ぐりとぐら"),
                .init(userName: "山田太郎", bookTitle: "はらぺこあおむし"),
            ]
        )
        
        XCTAssertTrue(message.contains("借りたままの図書が2冊あります。削除すると自動的に返却されます。"))
        XCTAssertTrue(message.contains("・山田太郎さん『ぐりとぐら』"))
        XCTAssertTrue(message.contains("・山田太郎さん『はらぺこあおむし』"))
    }
    
    /// 貸出がない場合に自動返却の案内を出さないことの確認
    ///
    /// 「自動的に返却されます」は起きることの予告なので、
    /// 何も起きないときに出すと不要な不安を与えるため
    func testNoLoanNoticeWhenNothingIsBorrowed() {
        let message = UserDeletionMessage.make(
            targetNames: ["山田太郎"],
            cascadedGuardianNames: ["山田花子"],
            autoReturningLoans: []
        )
        
        XCTAssertFalse(message.contains("自動的に返却されます"))
    }
}
