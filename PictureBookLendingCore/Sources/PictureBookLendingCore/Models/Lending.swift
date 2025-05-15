import Foundation

public struct Lending: Identifiable {
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
