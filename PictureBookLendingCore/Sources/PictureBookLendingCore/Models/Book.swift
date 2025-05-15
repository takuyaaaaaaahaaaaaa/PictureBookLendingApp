import Foundation

public struct Book: Identifiable, Codable {
    public var id: UUID
    public var title: String
    public var author: String
    
    public init(id: UUID = UUID(), title: String, author: String) {
        self.id = id
        self.title = title
        self.author = author
    }
}
