import Foundation

/// 絵本の対象読者の定義
///
/// 保育園・幼稚園で利用する絵本の適合年齢を表現するドメインエンティティ
public enum TargetAudience: String, CaseIterable, Codable, Sendable {
    /// 乳児
    case infant = "乳児"
    /// 幼児
    case toddler = "幼児"
    /// 小学校低学年
    case lowerElementary = "小学校低学年"
    /// 小学校高学年
    case upperElementary = "小学校高学年"
    /// 中高生
    case juniorHighSchool = "中高生"
    /// 大人
    case adult = "大人"
    
    /// 表示用のテキスト
    public var displayText: String {
        return self.rawValue
    }
    
    /// 順序付きの全ケース
    public static var sortedCases: [TargetAudience] {
        return allCases
    }
}
