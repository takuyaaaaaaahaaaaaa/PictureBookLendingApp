import Foundation

public struct AdminUser: Identifiable {
    public let id: UUID
    public let username: String
    public let password: String
    public let role: AdminRole
    
    public init(id: UUID = UUID(), username: String, password: String, role: AdminRole) {
        self.id = id
        self.username = username
        self.password = password
        self.role = role
    }
}

public enum AdminRole {
    case superAdmin
    case librarian
}
