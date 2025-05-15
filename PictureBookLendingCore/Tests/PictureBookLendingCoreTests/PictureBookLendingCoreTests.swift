import XCTest
@testable import PictureBookLendingCore

final class PictureBookLendingCoreTests: XCTestCase {
    func testBookCreation() {
        let book = Book(title: "Test Book", author: "Test Author", isbn: "1234567890", publishedYear: 2025)
        XCTAssertEqual(book.title, "Test Book")
        XCTAssertEqual(book.author, "Test Author")
        XCTAssertEqual(book.isbn, "1234567890")
        XCTAssertEqual(book.publishedYear, 2025)
    }
    
    func testUserCreation() {
        let user = User(name: "Test User", email: "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
    }
    
    func testLendingCreation() {
        let now = Date()
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: now)!
        let lending = Lending(bookId: UUID(), userId: UUID(), lendDate: now, dueDate: dueDate)
        XCTAssertEqual(lending.lendDate, now)
        XCTAssertEqual(lending.dueDate, dueDate)
        XCTAssertNil(lending.returnDate)
    }
    
    func testBookService() {
        let service = BookService()
        let books = service.getBooks()
        XCTAssertFalse(books.isEmpty)
    }
    
    func testLendingService() {
        let service = LendingService()
        let lending = service.borrowBook(userId: UUID(), bookId: UUID())
        XCTAssertNotNil(lending)
    }
}
