import Foundation

public class BookManagementService {
    public init() {}
    
    public func addBook(title: String, author: String, isbn: String, publishedYear: Int) -> Book {
        return Book(title: title, author: author, isbn: isbn, publishedYear: publishedYear)
    }
    
    public func lendBook(bookId: UUID, userId: UUID, dueDate: Date) -> Lending {
        return Lending(
            bookId: bookId,
            userId: userId,
            lendDate: Date(),
            dueDate: dueDate
        )
    }
    
    public func returnBook(lendingId: UUID) -> Lending {
        return Lending(
            bookId: UUID(),
            userId: UUID(),
            lendDate: Date().addingTimeInterval(-7*24*60*60), // 1 week ago
            dueDate: Date().addingTimeInterval(7*24*60*60),   // 1 week from now
            returnDate: Date()
        )
    }
}
