import Foundation

/// ISBN検証・正規化のためのユーティリティ
public enum ISBNValidator {
    
    /// ISBNを正規化する（ハイフンを除去し、大文字に変換）
    /// - Parameter isbn: 正規化するISBN文字列
    /// - Returns: 正規化されたISBN文字列
    public static func normalize(_ isbn: String) -> String {
        return
            isbn
            .uppercased()
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// ISBN-13の形式とチェックサムを検証する
    /// - Parameter isbn: 検証するISBN-13文字列
    /// - Returns: 有効なISBN-13の場合true
    public static func isValidISBN13(_ isbn: String) -> Bool {
        let normalized = normalize(isbn)
        
        // 13桁であることを確認
        guard normalized.count == 13 else { return false }
        
        // 全て数字であることを確認
        guard normalized.allSatisfy(\.isNumber) else { return false }
        
        // ISBN-13のプレフィックスを確認
        // 978: 書籍用のEAN-13プレフィックス（Bookland）
        // 979: 音楽出版物および書籍用の追加プレフィックス
        guard normalized.hasPrefix("978") || normalized.hasPrefix("979") else { return false }
        
        // チェックサムを検証
        let digits = normalized.compactMap { Int(String($0)) }
        guard digits.count == 13 else { return false }
        
        let checksum = digits.enumerated().reduce(0) { sum, pair in
            let (index, digit) = pair
            let weight = (index % 2 == 0) ? 1 : 3
            return sum + digit * weight
        }
        
        return checksum % 10 == 0
    }
    
    /// ISBN-10の形式とチェックサムを検証する
    /// - Parameter isbn: 検証するISBN-10文字列
    /// - Returns: 有効なISBN-10の場合true
    public static func isValidISBN10(_ isbn: String) -> Bool {
        let normalized = normalize(isbn)
        
        // 10桁であることを確認
        guard normalized.count == 10 else { return false }
        
        let characters = Array(normalized)
        var sum = 0
        
        // 最初の9桁は数字、最後の1桁は数字またはX
        for i in 0..<10 {
            let char = characters[i]
            let value: Int
            
            if i == 9 && (char == "X") {
                value = 10
            } else if let digit = char.wholeNumberValue {
                value = digit
            } else {
                return false
            }
            
            sum += value * (10 - i)
        }
        
        return sum % 11 == 0
    }
    
    /// ISBN-10またはISBN-13のいずれかとして有効かを検証する
    /// - Parameter isbn: 検証するISBN文字列
    /// - Returns: 有効なISBNの場合true
    public static func isValidISBN(_ isbn: String) -> Bool {
        return isValidISBN13(isbn) || isValidISBN10(isbn)
    }
}
