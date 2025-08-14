import Foundation

/// 利用者のクラス（組）を表すエンティティ
public struct ClassGroup: Identifiable, Equatable, Sendable, Codable, Hashable {
    /// 一意な識別子
    public let id: UUID
    
    /// クラス名（例: "ひよこ組"）
    public var name: String
    
    /// 年齢グループ（例: "0歳児", "1歳児", "大人"など）
    public var ageGroup: String
    
    /// 年度（例: 2025）
    public var year: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        ageGroup: String,
        year: Int
    ) {
        self.id = id
        self.name = name
        self.ageGroup = ageGroup
        self.year = year
    }
}
