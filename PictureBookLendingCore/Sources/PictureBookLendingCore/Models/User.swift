import Foundation

public struct User: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var group: String  // クラス/組
    
    public init(id: UUID = UUID(), name: String, group: String) {
        self.id = id
        self.name = name
        self.group = group
    }
}
