import Foundation

/// アプリ全体で使用する定数定義
public enum Const {
    
    /// 年齢グループの定義
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
    }
}
