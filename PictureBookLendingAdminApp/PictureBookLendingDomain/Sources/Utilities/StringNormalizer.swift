import Foundation

/// 文字列を正規化するプロトコル
/// 日本語の表記ゆれを統一し、検索精度を向上させる
public protocol StringNormalizer: Sendable {
    /// 文字列を正規化する
    /// - Parameter input: 入力文字列
    /// - Returns: 正規化された文字列
    func normalize(_ input: String) -> String
    
    /// タイトル用の正規化
    /// - Parameter title: 絵本のタイトル
    /// - Returns: 正規化されたタイトル
    func normalizeTitle(_ title: String) -> String
    
    /// 著者名用の正規化
    /// - Parameter author: 著者名
    /// - Returns: 正規化された著者名
    func normalizeAuthor(_ author: String) -> String
}

// MARK: - Default Implementation
extension StringNormalizer {
    public func normalizeTitle(_ title: String) -> String {
        normalize(title)
    }
    
    public func normalizeAuthor(_ author: String) -> String {
        normalize(author)
    }
}

/// 日本語文字列の正規化に関する共通処理
public enum NormalizationHelper {
    /// 全角英数字を半角に変換する文字マップ
    public static let fullWidthToHalfWidthMap: [Character: Character] = [
        "０": "0", "１": "1", "２": "2", "３": "3", "４": "4",
        "５": "5", "６": "6", "７": "7", "８": "8", "９": "9",
        "Ａ": "A", "Ｂ": "B", "Ｃ": "C", "Ｄ": "D", "Ｅ": "E",
        "Ｆ": "F", "Ｇ": "G", "Ｈ": "H", "Ｉ": "I", "Ｊ": "J",
        "Ｋ": "K", "Ｌ": "L", "Ｍ": "M", "Ｎ": "N", "Ｏ": "O",
        "Ｐ": "P", "Ｑ": "Q", "Ｒ": "R", "Ｓ": "S", "Ｔ": "T",
        "Ｕ": "U", "Ｖ": "V", "Ｗ": "W", "Ｘ": "X", "Ｙ": "Y",
        "Ｚ": "Z",
        "ａ": "a", "ｂ": "b", "ｃ": "c", "ｄ": "d", "ｅ": "e",
        "ｆ": "f", "ｇ": "g", "ｈ": "h", "ｉ": "i", "ｊ": "j",
        "ｋ": "k", "ｌ": "l", "ｍ": "m", "ｎ": "n", "ｏ": "o",
        "ｐ": "p", "ｑ": "q", "ｒ": "r", "ｓ": "s", "ｔ": "t",
        "ｕ": "u", "ｖ": "v", "ｗ": "w", "ｘ": "x", "ｙ": "y",
        "ｚ": "z",
        "　": " ",  // 全角スペースを半角スペースに
    ]

    /// よく使われる記号の正規化マップ
    public static let symbolNormalizationMap: [Character: Character] = [
        "・": " ",  // 中黒をスペースに
        "･": " ",  // 半角中黒をスペースに
        "－": "-",  // 全角ハイフンを半角に
        "—": "-",  // emダッシュを半角ハイフンに
        "―": "-",  // ホリゾンタルバーを半角ハイフンに
        "‐": "-",  // ハイフンを半角ハイフンに
        "～": "~",  // 全角チルダを半角に
        "〜": "~",  // 波ダッシュを半角チルダに
        "（": "(",  // 全角括弧を半角に
        "）": ")",
        "［": "[",
        "］": "]",
        "｛": "{",
        "｝": "}",
        "：": ":",  // 全角コロンを半角に
        "；": ";",
        "！": "!",
        "？": "?",
    ]

    /// 旧字体・異体字の正規化マップ（一部）
    public static let variantCharacterMap: [Character: Character] = [
        "髙": "高",
        "﨑": "崎",
        "德": "徳",
        "濵": "浜",
        "凜": "凛",
        "祐": "祐",  // 異体字
        "礼": "礼",  // 異体字
    ]

    /// 著者名の役割語（これらは削除される）
    public static let authorRoleSuffixes = [
        "作", "著", "文", "絵", "画", "訳", "編",
        "さく", "ちょ", "ぶん", "え", "やく", "へん",
    ]
    
    /// カタカナをひらがなに変換
    public static func katakanaToHiragana(_ text: String) -> String {
        let mutableString = NSMutableString(string: text) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformHiraganaKatakana as NSString, true)
        return mutableString as String
    }
    
    /// 連続するスペースを1つに統一
    public static func normalizeSpaces(_ text: String) -> String {
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
