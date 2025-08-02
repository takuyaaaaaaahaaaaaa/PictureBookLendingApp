import Foundation

/// 絵本検索結果のスコアリングサービス
///
/// 検索クエリ（タイトル・著者）と検索結果の関連度を数値で評価します。
/// スコアが高いほど検索意図により適した結果であることを示します。
public struct BookSearchScorer: Sendable {
    public init() {}
    
    /// 検索結果をスコアリング
    /// - Parameters:
    ///   - searchQuery: 検索クエリ
    ///   - books: 検索結果の絵本配列
    /// - Returns: スコア付きの絵本配列（スコア降順）
    public func scoreSearchResults(
        searchQuery: BookSearchQuery,
        books: [Book]
    ) -> [ScoredBook] {
        let scoredBooks = books.map { book in
            let score = calculateScore(searchQuery: searchQuery, book: book)
            return ScoredBook(book: book, score: score)
        }
        
        return scoredBooks.sorted { $0.score > $1.score }
    }
    
    /// 個別の絵本に対するスコア計算
    /// - Parameters:
    ///   - searchQuery: 検索クエリ
    ///   - book: 評価対象の絵本
    /// - Returns: スコア（0.0 - 1.0）
    public func calculateScore(
        searchQuery: BookSearchQuery,
        book: Book
    ) -> Double {
        var totalScore = 0.0
        var totalWeight = 0.0
        
        // タイトルマッチスコア（重み: 70%）- タイトルが空でない場合のみ
        if !searchQuery.title.trimmingCharacters(in: .whitespaces).isEmpty {
            let titleWeight = 0.7
            let titleScore = calculateTitleMatchScore(
                searchTitle: searchQuery.title,
                bookTitle: book.title
            )
            totalScore += titleScore * titleWeight
            totalWeight += titleWeight
        }
        
        // 著者マッチスコア（重み: 30%）
        if let searchAuthor = searchQuery.author {
            let authorWeight = 0.3
            let authorScore = calculateAuthorMatchScore(
                searchAuthor: searchAuthor,
                bookAuthor: book.author
            )
            totalScore += authorScore * authorWeight
            totalWeight += authorWeight
        }
        
        return totalWeight > 0 ? totalScore / totalWeight : 0.0
    }
    
    // MARK: - Private Methods
    
    /// タイトルのマッチスコアを計算
    private func calculateTitleMatchScore(
        searchTitle: String,
        bookTitle: String
    ) -> Double {
        let normalizedSearchTitle = normalizeForScoring(searchTitle)
        let normalizedBookTitle = normalizeForScoring(bookTitle)
        
        // 完全一致（最高スコア）
        if normalizedSearchTitle == normalizedBookTitle {
            return 1.0
        }
        
        // 前方一致
        if normalizedBookTitle.hasPrefix(normalizedSearchTitle) {
            return 0.9
        }
        
        // 部分一致（検索語が書籍タイトルに含まれる）
        if normalizedBookTitle.contains(normalizedSearchTitle) {
            return 0.8
        }
        
        // 逆方向部分一致（書籍タイトルが検索語に含まれる）
        if normalizedSearchTitle.contains(normalizedBookTitle) {
            return 0.7
        }
        
        // 文字レベルの類似度（Levenshtein距離ベース）
        let similarity = calculateStringSimilarity(
            normalizedSearchTitle,
            normalizedBookTitle
        )
        
        // 類似度が0.5以上の場合のみスコアとして採用
        return similarity >= 0.5 ? similarity * 0.6 : 0.0
    }
    
    /// 著者のマッチスコアを計算
    private func calculateAuthorMatchScore(
        searchAuthor: String,
        bookAuthor: String
    ) -> Double {
        let normalizedSearchAuthor = normalizeForScoring(searchAuthor)
        let normalizedBookAuthor = normalizeForScoring(bookAuthor)
        
        // 完全一致
        if normalizedSearchAuthor == normalizedBookAuthor {
            return 1.0
        }
        
        // 部分一致（著者名の一部が一致）
        if normalizedBookAuthor.contains(normalizedSearchAuthor)
            || normalizedSearchAuthor.contains(normalizedBookAuthor)
        {
            return 0.8
        }
        
        // 文字レベルの類似度
        let similarity = calculateStringSimilarity(
            normalizedSearchAuthor,
            normalizedBookAuthor
        )
        
        return similarity >= 0.6 ? similarity * 0.7 : 0.0
    }
    
    /// スコアリング用の文字列正規化
    private func normalizeForScoring(_ text: String) -> String {
        var normalized = text.lowercased()
        
        // 空白文字の統一
        normalized = normalized.replacingOccurrences(of: "　", with: " ")
        normalized = normalized.replacingOccurrences(
            of: "\\s+", with: " ", options: .regularExpression)
        normalized = normalized.trimmingCharacters(in: .whitespaces)
        
        // 記号の除去
        let symbolsToRemove = ["・", "･", "·", "－", "―", "ー", "～", "〜", "：", ":", "／", "/"]
        for symbol in symbolsToRemove {
            normalized = normalized.replacingOccurrences(of: symbol, with: "")
        }
        
        return normalized
    }
    
    /// 文字列間の類似度を計算（Levenshtein距離ベース）
    private func calculateStringSimilarity(_ string1: String, _ string2: String) -> Double {
        let distance = levenshteinDistance(string1, string2)
        let maxLength = max(string1.count, string2.count)
        
        guard maxLength > 0 else { return 1.0 }
        
        return 1.0 - Double(distance) / Double(maxLength)
    }
    
    /// Levenshtein距離の計算
    private func levenshteinDistance(_ string1: String, _ string2: String) -> Int {
        let array1 = Array(string1)
        let array2 = Array(string2)
        
        let rows = array1.count + 1
        let cols = array2.count + 1
        
        var matrix = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        
        // 初期化
        for i in 0..<rows {
            matrix[i][0] = i
        }
        for j in 0..<cols {
            matrix[0][j] = j
        }
        
        // 動的プログラミング
        for i in 1..<rows {
            for j in 1..<cols {
                if array1[i - 1] == array2[j - 1] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = min(
                        matrix[i - 1][j] + 1,  // 削除
                        matrix[i][j - 1] + 1,  // 挿入
                        matrix[i - 1][j - 1] + 1  // 置換
                    )
                }
            }
        }
        
        return matrix[rows - 1][cols - 1]
    }
}

/// 検索クエリを表現する構造体
public struct BookSearchQuery: Equatable, Sendable {
    public let title: String
    public let author: String?
    
    public init(title: String, author: String? = nil) {
        self.title = title
        self.author = author
    }
}

/// スコア付きの絵本
public struct ScoredBook: Equatable, Sendable {
    public let book: Book
    public let score: Double
    
    public init(book: Book, score: Double) {
        self.book = book
        self.score = score
    }
}
