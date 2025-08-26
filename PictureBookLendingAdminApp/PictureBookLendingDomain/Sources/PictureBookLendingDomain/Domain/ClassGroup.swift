import Foundation

/// 利用者のクラス（組）を表すエンティティ
public struct ClassGroup: Identifiable, Equatable, Sendable, Codable, Hashable {
    /// 一意な識別子
    public let id: UUID
    
    /// クラス名（例: "ひよこ組"）
    public var name: String
    
    /// 年齢グループ
    public var ageGroup: AgeGroup
    
    /// 年度（例: 2025）
    public var year: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        ageGroup: AgeGroup,
        year: Int
    ) {
        self.id = id
        self.name = name
        self.ageGroup = ageGroup
        self.year = year
    }
}
