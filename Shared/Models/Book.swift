import Foundation

public struct Book: Identifiable {
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
