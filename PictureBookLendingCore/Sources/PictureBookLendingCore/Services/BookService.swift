import Foundation

public class BookService {
    public init() {}
    
    public func getBooks() -> [Book] {
        return [
            Book(title: "はらぺこあおむし", author: "エリック・カール", isbn: "978-4033280103", publishedYear: 1976),
            Book(title: "ぐりとぐら", author: "中川李枝子", isbn: "978-4834000825", publishedYear: 1967),
            Book(title: "The Very Hungry Caterpillar", author: "Eric Carle", isbn: "978-0399226908", publishedYear: 1969),
            Book(title: "Where the Wild Things Are", author: "Maurice Sendak", isbn: "978-0060254926", publishedYear: 1963)
        ]
    }
    
    public func getBookById(id: UUID) -> Book? {
        return getBooks().first { $0.id == id }
    }
}
