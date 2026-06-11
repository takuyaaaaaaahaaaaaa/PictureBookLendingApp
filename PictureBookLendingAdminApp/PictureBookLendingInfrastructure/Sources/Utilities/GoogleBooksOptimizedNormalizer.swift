import Foundation
import PictureBookLendingDomain

/// Google Books API用に最適化された文字列正規化実装
///
/// Google Books APIの検索特性に合わせて正規化を行います：
/// - タイトル: スペースを削除（「ぐり と ぐら」→「ぐりとぐら」）
/// - 著者: 中黒をスペースに変換、役割語を削除
public struct GoogleBooksOptimizedNormalizer: StringNormalizer {
    public init() {}
    
    public func normalize(_ input: String) -> String {
        var text = input
        
        // 1. 前後の空白を削除
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. 全角英数字を半角に変換
        text = convertFullWidthToHalfWidth(text)
        
        // 3. 記号を正規化
        text = normalizeSymbols(text)
        
        // 4. 旧字体・異体字を正規化
        text = normalizeVariantCharacters(text)
        
        // 5. 連続するスペースを1つに統一
        text = NormalizationHelper.normalizeSpaces(text)
        
        // 6. 最終的なトリム
        text = text.trimmingCharacters(in: .whitespaces)
        
        return text
    }
    
    public func normalizeTitle(_ title: String) -> String {
        var text = title
        
        // 1. 前後の空白を削除
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. 全角英数字を半角に変換
        text = convertFullWidthToHalfWidth(text)
        
        // 3. 記号を正規化（スペースに変換）
        text = normalizeSymbols(text)
        
        // 4. 旧字体・異体字を正規化
        text = normalizeVariantCharacters(text)
        
        // 5. 【重要】タイトルではスペースを完全に削除
        // Google Books APIはタイトル内のスペースがない方が精度が高い
        text = text.replacingOccurrences(of: " ", with: "")
        text = text.replacingOccurrences(of: "　", with: "")
        text = text.replacingOccurrences(of: "\t", with: "")
        
        return text
    }
    
    public func normalizeAuthor(_ author: String) -> String {
        var text = author
        
        // 1. 前後の空白を削除
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. 全角英数字を半角に変換
        text = convertFullWidthToHalfWidth(text)
        
        // 3. 記号を正規化（スペースに変換）
        text = normalizeSymbols(text)
        
        // 4. 旧字体・異体字を正規化
        text = normalizeVariantCharacters(text)
        
        // 5. 役割語の除去
        text = removeAuthorRoleSuffixes(text)
        
        // 6. 連続するスペースを1つに統一（著者名ではスペースを残す）
        text = NormalizationHelper.normalizeSpaces(text)
        
        // 7. 最終的なトリム
        text = text.trimmingCharacters(in: .whitespaces)
        
        return text
    }
    
    // MARK: - Private Methods
    
    /// 全角英数字を半角に変換
    private func convertFullWidthToHalfWidth(_ text: String) -> String {
        var result = text
        
        // 全角文字を半角に変換
        for (full, half) in NormalizationHelper.fullWidthToHalfWidthMap {
            result = result.replacingOccurrences(of: String(full), with: String(half))
        }
        
        return result
    }
    
    /// 記号を正規化
    private func normalizeSymbols(_ text: String) -> String {
        var result = text
        
        // 各種記号をスペースに変換
        let symbolsToSpace = [
            "・", "･", "·",  // 中黒
            "－", "―", "ー", "─",  // ハイフン・長音符
            "～", "〜",  // 波ダッシュ
            "：", ":",  // コロン
            "／", "/",  // スラッシュ
            "（", "）", "(", ")",  // 括弧
            "「", "」", "『", "』",  // かぎ括弧
        ]
        
        for symbol in symbolsToSpace {
            result = result.replacingOccurrences(of: symbol, with: " ")
        }
        
        return result
    }
    
    /// 旧字体・異体字を正規化
    private func normalizeVariantCharacters(_ text: String) -> String {
        var result = text
        
        // よく使われる異体字の正規化
        let variants: [String: String] = [
            "渡邊": "渡辺",
            "渡邉": "渡辺",
            "齋藤": "斎藤",
            "齊藤": "斎藤",
            "髙": "高",
            "﨑": "崎",
        ]

        for (variant, standard) in variants {
            result = result.replacingOccurrences(of: variant, with: standard)
        }
        
        return result
    }
    
    /// 著者名の役割語を除去
    private func removeAuthorRoleSuffixes(_ text: String) -> String {
        var result = text
        
        // 役割語のパターン（優先順位順）
        let roleSuffixes = [
            // 括弧付きパターン
            "（さく）", "(さく)", "〔さく〕", "[さく]",
            "（作）", "(作)", "〔作〕", "[作]",
            "（文）", "(文)", "〔文〕", "[文]",
            "（絵）", "(絵)", "〔絵〕", "[絵]",
            "（訳）", "(訳)", "〔訳〕", "[訳]",
            "（著）", "(著)", "〔著〕", "[著]",
            "（編）", "(編)", "〔編〕", "[編]",
            // 役割語のみ
            "さく", "作", "文", "絵", "え", "訳", "やく", "著", "編",
        ]
        
        for suffix in roleSuffixes {
            if result.hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
                result = result.trimmingCharacters(in: .whitespaces)
            }
        }
        
        // 複合パターン（「作・絵」など）
        let compoundPatterns = [
            "作・絵", "さく・え", "文・絵", "ぶん・え",
        ]
        
        for pattern in compoundPatterns {
            if result.hasSuffix(pattern) {
                result = String(result.dropLast(pattern.count))
                result = result.trimmingCharacters(in: .whitespaces)
            }
        }
        
        return result
    }
}
