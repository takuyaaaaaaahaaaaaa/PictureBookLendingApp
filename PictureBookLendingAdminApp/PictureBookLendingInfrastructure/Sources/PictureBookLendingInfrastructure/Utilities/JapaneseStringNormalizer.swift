import Foundation
import PictureBookLendingDomain

/// 日本語文字列の正規化実装
public struct JapaneseStringNormalizer: StringNormalizer {
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
        let text = normalize(title)
        
        // タイトル特有の処理
        // カタカナをひらがなに変換（オプション：検索精度向上のため）
        // text = NormalizationHelper.katakanaToHiragana(text)
        
        return text
    }
    
    public func normalizeAuthor(_ author: String) -> String {
        var text = normalize(author)
        
        // 著者名特有の処理
        // 役割語の除去
        text = removeAuthorRoleSuffixes(text)
        
        return text
    }
    
    // MARK: - Private Methods
    
    private func convertFullWidthToHalfWidth(_ text: String) -> String {
        var result = ""
        for char in text {
            if let halfWidth = NormalizationHelper.fullWidthToHalfWidthMap[char] {
                result.append(halfWidth)
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    private func normalizeSymbols(_ text: String) -> String {
        var result = ""
        for char in text {
            if let normalized = NormalizationHelper.symbolNormalizationMap[char] {
                result.append(normalized)
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    private func normalizeVariantCharacters(_ text: String) -> String {
        var result = ""
        for char in text {
            if let normalized = NormalizationHelper.variantCharacterMap[char] {
                result.append(normalized)
            } else {
                result.append(char)
            }
        }
        return result
    }
    
    private func removeAuthorRoleSuffixes(_ text: String) -> String {
        var result = text
        
        // 括弧内の役割語を削除（例：「宮沢賢治（作）」→「宮沢賢治」）
        result = result.replacingOccurrences(
            of: "\\s*[（(][^）)]*[）)]\\s*$",
            with: "",
            options: .regularExpression
        )
        
        // 末尾の役割語を削除
        for suffix in NormalizationHelper.authorRoleSuffixes {
            if result.hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
                result = result.trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        return result
    }
}

// MARK: - Factory
extension StringNormalizer where Self == JapaneseStringNormalizer {
    /// デフォルトの日本語正規化実装
    public static var japanese: StringNormalizer {
        JapaneseStringNormalizer()
    }
}
