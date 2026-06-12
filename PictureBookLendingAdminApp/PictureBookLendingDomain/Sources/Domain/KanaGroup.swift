import Foundation

/// 五十音順グループ
/// 絵本のタイトルを五十音順で分類するためのグループ定義
public enum KanaGroup: String, CaseIterable, Sendable, Codable {
    case a = "あ"
    case ka = "か"
    case sa = "さ"
    case ta = "た"
    case na = "な"
    case ha = "は"
    case ma = "ま"
    case ya = "や"
    case ra = "ら"
    case wa = "わ"
    case other = "他"
    
    /// 表示用の名前
    public var displayName: String {
        rawValue
    }
    
    /// 五十音グループの順序（並び替え用）
    public var sortOrder: Int {
        switch self {
        case .a: return 0
        case .ka: return 1
        case .sa: return 2
        case .ta: return 3
        case .na: return 4
        case .ha: return 5
        case .ma: return 6
        case .ya: return 7
        case .ra: return 8
        case .wa: return 9
        case .other: return 10
        }
    }
    
    /// 五十音グループの文字範囲を定義
    private static let groupRanges: [KanaGroup: [Character]] = [
        .a: ["あ", "い", "う", "え", "お"],
        .ka: ["か", "き", "く", "け", "こ", "が", "ぎ", "ぐ", "げ", "ご"],
        .sa: ["さ", "し", "す", "せ", "そ", "ざ", "じ", "ず", "ぜ", "ぞ"],
        .ta: ["た", "ち", "つ", "て", "と", "だ", "ぢ", "づ", "で", "ど"],
        .na: ["な", "に", "ぬ", "ね", "の"],
        .ha: ["は", "ひ", "ふ", "へ", "ほ", "ば", "び", "ぶ", "べ", "ぼ", "ぱ", "ぴ", "ぷ", "ぺ", "ぽ"],
        .ma: ["ま", "み", "む", "め", "も"],
        .ya: ["や", "ゆ", "よ"],
        .ra: ["ら", "り", "る", "れ", "ろ"],
        .wa: ["わ", "ゐ", "ゑ", "を", "ん"],
    ]

    /// 文字から五十音グループを取得
    /// - Parameter character: 判定対象の文字
    /// - Returns: 対応する五十音グループ、該当しない場合は.other
    public static func from(character: Character) -> KanaGroup {
        for (group, characters) in groupRanges {
            if characters.contains(character) {
                return group
            }
        }
        return .other
    }
    
    /// テキストから五十音グループを取得
    /// - Parameter text: 判定対象のテキスト（絵本タイトルなど）
    /// - Returns: 対応する五十音グループ、該当しない場合は.other
    public static func from(text: String) -> KanaGroup {
        // 空文字列の場合は.otherを返す
        guard !text.isEmpty else { return .other }
        
        // テキストをひらがなに変換
        let hiraganaText = text.toHiragana()
        
        // 最初の文字で判定
        guard let firstCharacter = hiraganaText.first else { return .other }
        
        return from(character: firstCharacter)
    }
}

/// 文字列の拡張 - 五十音分類用のユーティリティ
extension String {
    /// 文字列をひらがなに変換
    /// 漢字、カタカナ、ローマ字をひらがなに変換する
    /// - Returns: ひらがなに変換された文字列
    public func toHiragana() -> String {
        // CFStringTransformを使用してひらがなに変換
        let mutableString = NSMutableString(string: self)
        
        // ローマ字 → ひらがな
        CFStringTransform(mutableString, nil, kCFStringTransformLatinHiragana, false)
        
        // カタカナ → ひらがな
        CFStringTransform(mutableString, nil, "Katakana-Hiragana" as CFString, false)
        
        // 漢字 → ひらがな（読み）
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformLatinHiragana, false)
        
        return mutableString as String
    }
    
    /// 文字列から五十音グループを取得
    /// - Returns: 対応する五十音グループ
    public func kanaGroup() -> KanaGroup {
        return KanaGroup.from(text: self)
    }
}
