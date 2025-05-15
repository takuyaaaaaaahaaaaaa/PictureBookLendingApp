import Foundation
import PictureBookLendingCore

public class BookBrowsingService {
    public init() {}
    
    public func searchBooks(byTitle title: String? = nil, byAuthor author: String? = nil) -> [Book] {
        return [
            Book(title: "The Very Hungry Caterpillar", author: "Eric Carle", isbn: "978-0399226908", publishedYear: 1969),
            Book(title: "Where the Wild Things Are", author: "Maurice Sendak", isbn: "978-0060254926", publishedYear: 1963),
            Book(title: "Goodnight Moon", author: "Margaret Wise Brown", isbn: "978-0694003617", publishedYear: 1947)
        ]
    }
}

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
