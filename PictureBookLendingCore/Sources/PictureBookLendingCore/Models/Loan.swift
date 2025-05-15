import Foundation

public struct Loan: Identifiable, Codable {
    public var id: UUID
    public var bookId: UUID
    public var userId: UUID
    public var loanDate: Date
    public var dueDate: Date
    public var returnedDate: Date?
    
    public var isReturned: Bool {
        returnedDate != nil
    }
    
    public init(id: UUID = UUID(), bookId: UUID, userId: UUID, loanDate: Date, dueDate: Date, returnedDate: Date? = nil) {
        self.id = id
        self.bookId = bookId
        self.userId = userId
        self.loanDate = loanDate
        self.dueDate = dueDate
        self.returnedDate = returnedDate
    }
}
