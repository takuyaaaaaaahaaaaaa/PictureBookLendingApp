import Foundation

public struct User: Identifiable {
    public let id: UUID
    public let name: String
    public let email: String
    
    public init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}
