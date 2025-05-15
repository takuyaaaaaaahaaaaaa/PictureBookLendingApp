import Foundation

public struct Book {
    public let id: UUID
    public let title: String
    public let author: String
    public let isbn: String
    public let publishedYear: Int
    
    public init(id: UUID = UUID(), title: String, author: String, isbn: String, publishedYear: Int) {
        self.id = id
        self.title = title
        self.author = author
        self.isbn = isbn
        self.publishedYear = publishedYear
    }
}

public struct User {
    public let id: UUID
    public let name: String
    public let email: String
    
    public init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

public struct Lending {
    public let id: UUID
    public let bookId: UUID
    public let userId: UUID
    public let lendDate: Date
    public let dueDate: Date
    public let returnDate: Date?
    
    public init(id: UUID = UUID(), bookId: UUID, userId: UUID, lendDate: Date, dueDate: Date, returnDate: Date? = nil) {
        self.id = id
        self.bookId = bookId
        self.userId = userId
        self.lendDate = lendDate
        self.dueDate = dueDate
        self.returnDate = returnDate
    }
}
