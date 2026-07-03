import XCTest

@testable import PictureBookLendingDomain

final class LoanTests: XCTestCase {
    
    private func makeLoan(dueDate: Date, returnedDate: Date? = nil) -> Loan {
        Loan(
            bookId: UUID(),
            user: User(name: "いとう さくら", classGroupId: UUID()),
            loanDate: dueDate.addingTimeInterval(-7 * 24 * 60 * 60),
            dueDate: dueDate,
            returnedDate: returnedDate
        )
    }
    
    func testIsOverdueBeforeDueDate() {
        let dueDate = Date()
        let loan = makeLoan(dueDate: dueDate)
        
        XCTAssertFalse(loan.isOverdue(at: dueDate.addingTimeInterval(-60)))
    }
    
    func testIsOverdueAtExactDueDate() {
        let dueDate = Date()
        let loan = makeLoan(dueDate: dueDate)
        
        XCTAssertFalse(loan.isOverdue(at: dueDate), "期限ちょうどは延滞ではない")
    }
    
    func testIsOverdueAfterDueDate() {
        let dueDate = Date()
        let loan = makeLoan(dueDate: dueDate)
        
        XCTAssertTrue(loan.isOverdue(at: dueDate.addingTimeInterval(60)))
    }
    
    func testReturnedLoanIsNeverOverdue() {
        let dueDate = Date()
        let loan = makeLoan(dueDate: dueDate, returnedDate: dueDate.addingTimeInterval(120))
        
        XCTAssertFalse(loan.isOverdue(at: dueDate.addingTimeInterval(3600)), "返却済みの貸出は延滞ではない")
    }
}
