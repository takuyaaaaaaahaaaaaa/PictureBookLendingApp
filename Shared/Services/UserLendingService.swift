import Foundation

public class UserLendingService {
    public init() {}
    
    public func borrowBook(userId: UUID, bookId: UUID) -> Lending? {
        let dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        
        return Lending(
            bookId: bookId,
            userId: userId,
            lendDate: Date(),
            dueDate: dueDate
        )
    }
    
    public func getUserLendings(userId: UUID) -> [Lending] {
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let oneWeekLater = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        let twoWeeksLater = Calendar.current.date(byAdding: .day, value: 14, to: now)!
        
        return [
            Lending(bookId: UUID(), userId: userId, lendDate: oneWeekAgo, dueDate: oneWeekLater),
            Lending(bookId: UUID(), userId: userId, lendDate: oneWeekAgo, dueDate: twoWeeksLater, returnDate: now)
        ]
    }
}
