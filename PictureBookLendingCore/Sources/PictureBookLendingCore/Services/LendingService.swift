import Foundation

public class LendingService {
    public init() {}
    
    public func borrowBook(userId: UUID, bookId: UUID) -> Lending {
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        
        return Lending(
            bookId: bookId,
            userId: userId,
            lendDate: Date(),
            dueDate: dueDate
        )
    }
    
    public func returnBook(lendingId: UUID) -> Lending? {
        return Lending(
            bookId: UUID(),
            userId: UUID(),
            lendDate: Date().addingTimeInterval(-7*24*60*60), // 1 week ago
            dueDate: Date().addingTimeInterval(7*24*60*60),   // 1 week from now
            returnDate: Date()
        )
    }
}
