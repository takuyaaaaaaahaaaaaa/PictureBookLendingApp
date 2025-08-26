import Foundation

/// アプリ全体で使用する定数定義
public enum Const {
    
    /// 絵本の対象読者の定義
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
    
    /// 年齢グループの定義（クラス分け用）
    public enum AgeGroup: String, CaseIterable, Sendable {
        case infant0 = "0歳児"
        case infant1 = "1歳児"
        case infant2 = "2歳児"
        case infant3 = "3歳児"
        case infant4 = "4歳児"
        case infant5 = "5歳児"
        case adult = "大人"
        
        /// 表示用のテキスト
        public var displayText: String {
            return self.rawValue
        }
        
        /// 年齢順でソートされた全ケース
        public static var sortedCases: [AgeGroup] {
            return allCases
        }
        
        /// 次の年齢グループを取得（進級処理用）
        /// - Returns: 進級後の年齢グループ。5歳児の場合はnil（卒業）
        public func nextAgeGroup() -> AgeGroup? {
            switch self {
            case .infant0: return .infant1
            case .infant1: return .infant2
            case .infant2: return .infant3
            case .infant3: return .infant4
            case .infant4: return .infant5
            case .infant5: return nil  // 卒業
            case .adult: return .adult  // 変更なし
            }
        }
        
        /// 進級可能かどうかを判定
        /// - Returns: 進級可能な場合true、卒業の場合false
        public var canPromote: Bool {
            return nextAgeGroup() != nil
        }
    }
}
