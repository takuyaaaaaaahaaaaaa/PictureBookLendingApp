import Foundation

/// 年齢グループの定義（クラス分け用）
///
/// 保育園・幼稚園での利用者の年齢区分を表現する値オブジェクト
/// - 0-5歳児: 通常の年齢別クラス
/// - 大人・その他: 職員や特別な区分
public enum AgeGroup: Codable, Hashable, Sendable {
    case age(Int)  // 0-5歳児
    case other  // 大人・その他
    
    /// SwiftDataでの保存用にString形式で表現
    public var rawValue: String {
        switch self {
        case .age(let value): return "\(value)歳児"
        case .other: return "大人"
        }
    }
    
    /// String形式からAgeGroupを作成
    public init?(rawValue: String) {
        if rawValue == "大人" {
            self = .other
        } else if rawValue.hasSuffix("歳児") {
            let ageString = String(rawValue.dropLast(2))
            if let age = Int(ageString) {
                self = .age(age)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    /// 表示用のテキスト
    public var displayText: String {
        return rawValue
    }
    
    /// 年齢順でソートされた全ケース
    public static var sortedCases: [AgeGroup] {
        return [.age(0), .age(1), .age(2), .age(3), .age(4), .age(5), .other]
    }
    
    /// 次の年齢グループを取得（進級処理用）
    /// - Returns: 進級後の年齢グループ。5歳児の場合はnil（卒業）
    public func nextAgeGroup() -> AgeGroup? {
        switch self {
        case .age(let age):
            return age < 5 ? .age(age + 1) : nil  // 5歳児は卒業
        case .other:
            return .other  // 変更なし
        }
    }
    
    /// 進級可能かどうかを判定
    /// - Returns: 進級可能な場合true、卒業の場合false
    public var canPromote: Bool {
        switch self {
        case .age(let age): return age < 5
        case .other: return false
        }
    }
}
