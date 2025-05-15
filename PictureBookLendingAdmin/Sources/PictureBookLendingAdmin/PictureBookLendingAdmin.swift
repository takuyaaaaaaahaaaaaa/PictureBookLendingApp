import Foundation
import PictureBookLendingCore

public struct AdminUser {
    public let id: UUID
    public let username: String
    public let password: String
    public let role: AdminRole
    
    public init(id: UUID = UUID(), username: String, password: String, role: AdminRole) {
        self.id = id
        self.username = username
        self.password = password
        self.role = role
    }
}

public enum AdminRole {
    case superAdmin
    case librarian
}

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
