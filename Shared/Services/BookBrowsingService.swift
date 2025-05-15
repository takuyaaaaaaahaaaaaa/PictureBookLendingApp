import Foundation

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
