import Foundation
import Testing

@testable import PictureBookLendingDomain

@Suite("BookSearchScorer Tests")
struct BookSearchScorerTests {
    private let scorer = BookSearchScorer()
    
    // MARK: - Test Data
    
    private let sampleBooks = [
        Book(
            title: "ぐりとぐら",
            author: "なかがわりえこ",
            targetAge: 3
        ),
        Book(
            title: "ぐりとぐらのおきゃくさま",
            author: "なかがわりえこ",
            targetAge: 3
        ),
        Book(
            title: "はらぺこあおむし",
            author: "エリック・カール",
            targetAge: 2
        ),
        Book(
            title: "スイミー",
            author: "レオ・レオニ",
            targetAge: 4
        ),
    ]
    
    // MARK: - Title Match Score Tests
    
    @Test("完全一致タイトルは最高スコアを取得")
    func testPerfectTitleMatch() {
        let query = BookSearchQuery(title: "ぐりとぐら")
        let book = sampleBooks[0]  // "ぐりとぐら"
        
        let score = scorer.calculateScore(searchQuery: query, book: book)
        
        // タイトル完全一致なので高スコア（0.7以上）を期待
        #expect(score >= 0.7)
    }
    
    @Test("前方一致タイトルは高スコアを取得")
    func testPrefixTitleMatch() {
        let query = BookSearchQuery(title: "ぐりとぐら")
        let book = sampleBooks[1]  // "ぐりとぐらのおきゃくさま"
        
        let score = scorer.calculateScore(searchQuery: query, book: book)
        
        // 前方一致なので中程度以上のスコア（0.5以上）を期待
        #expect(score >= 0.5)
    }
    
    @Test("部分一致タイトルは中程度のスコアを取得")
    func testPartialTitleMatch() {
        let query = BookSearchQuery(title: "あおむし")
        let book = sampleBooks[2]  // "はらぺこあおむし"
        
        let score = scorer.calculateScore(searchQuery: query, book: book)
        
        // 部分一致なので中程度のスコア（0.3以上）を期待
        #expect(score >= 0.3)
    }
    
    @Test("無関係なタイトルは低スコアを取得")
    func testUnrelatedTitleMatch() {
        let query = BookSearchQuery(title: "存在しないタイトル")
        let book = sampleBooks[0]
        
        let score = scorer.calculateScore(searchQuery: query, book: book)
        
        // 無関係なので低スコア（0.3未満）を期待
        #expect(score < 0.3)
    }
    
    // MARK: - Author Match Score Tests
    
    @Test("タイトルと著者の両方が一致する場合の高スコア")
    func testTitleAndAuthorMatch() {
        let query = BookSearchQuery(title: "ぐりとぐら", author: "なかがわりえこ")
        let book = sampleBooks[0]
        
        let score = scorer.calculateScore(searchQuery: query, book: book)
        
        // タイトルと著者の両方が一致するので最高スコア（0.9以上）を期待
        #expect(score >= 0.9)
    }
    
    @Test("著者部分一致の効果")
    func testPartialAuthorMatch() {
        let query = BookSearchQuery(title: "ぐりとぐら", author: "なかがわ")
        let book = sampleBooks[0]  // author: "なかがわりえこ"
        
        let score = scorer.calculateScore(searchQuery: query, book: book)
        
        // 著者が部分一致するので高めのスコアを期待
        #expect(score >= 0.7)
    }
    
    @Test("著者が一致しない場合のスコア")
    func testAuthorMismatch() {
        let query = BookSearchQuery(title: "ぐりとぐら", author: "エリック・カール")
        let book = sampleBooks[0]  // author: "なかがわりえこ"
        
        let scoreWithWrongAuthor = scorer.calculateScore(searchQuery: query, book: book)
        
        let queryWithoutAuthor = BookSearchQuery(title: "ぐりとぐら")
        let scoreWithoutAuthor = scorer.calculateScore(searchQuery: queryWithoutAuthor, book: book)
        
        // 間違った著者を指定した場合、著者なしの場合よりスコアが低くなることを期待
        #expect(scoreWithWrongAuthor < scoreWithoutAuthor)
    }
    
    // MARK: - Search Results Scoring Tests
    
    @Test("検索結果のスコアリングと並び替え")
    func testSearchResultsScoring() {
        let query = BookSearchQuery(title: "ぐり", author: "なかがわりえこ")
        
        let scoredBooks = scorer.scoreSearchResults(searchQuery: query, books: sampleBooks)
        
        // 結果数が正しいことを確認
        #expect(scoredBooks.count == sampleBooks.count)
        
        // スコア順に並んでいることを確認
        for i in 0..<(scoredBooks.count - 1) {
            #expect(scoredBooks[i].score >= scoredBooks[i + 1].score)
        }
        
        // 最もマッチする結果が最初に来ることを確認
        // "ぐりとぐら" by "なかがわりえこ" が最高スコアになるはず
        let topResult = scoredBooks.first
        #expect(topResult?.book.title == "ぐりとぐら")
        #expect(topResult?.book.author == "なかがわりえこ")
    }
    
    @Test("空の検索結果の処理")
    func testEmptySearchResults() {
        let query = BookSearchQuery(title: "test")
        let emptyBooks: [Book] = []
        
        let scoredBooks = scorer.scoreSearchResults(searchQuery: query, books: emptyBooks)
        
        #expect(scoredBooks.isEmpty)
    }
    
    // MARK: - Edge Cases
    
    @Test("空文字列タイトルの処理")
    func testEmptyTitleQuery() {
        let query = BookSearchQuery(title: "")
        let book = sampleBooks[0]
        
        let score = scorer.calculateScore(searchQuery: query, book: book)
        
        // 空文字列なので低スコアを期待
        #expect(score < 0.1)
    }
    
    @Test("記号を含むタイトルの正規化")
    func testTitleWithSymbols() {
        let query = BookSearchQuery(title: "ぐり・と・ぐら")
        let book = sampleBooks[0]  // "ぐりとぐら"
        
        let score = scorer.calculateScore(searchQuery: query, book: book)
        
        // 記号が正規化されて一致するので高スコアを期待
        #expect(score >= 0.7)
    }
    
    @Test("大文字小文字の処理")
    func testCaseInsensitiveMatching() {
        let book = Book(
            title: "ABC Picture Book",
            author: "Test Author",
            targetAge: 3
        )
        
        let query1 = BookSearchQuery(title: "abc picture book")
        let query2 = BookSearchQuery(title: "ABC PICTURE BOOK")
        
        let score1 = scorer.calculateScore(searchQuery: query1, book: book)
        let score2 = scorer.calculateScore(searchQuery: query2, book: book)
        
        // 大文字小文字に関係なく同じスコアを期待
        #expect(abs(score1 - score2) < 0.01)
        #expect(score1 >= 0.7)
    }
    
    // MARK: - String Similarity Tests
    
    @Test("類似文字列の判定")
    func testStringSimilarity() {
        let book = Book(
            title: "はらぺこあおむし",
            author: "エリック・カール",
            targetAge: 2
        )
        
        // タイポを含むクエリ
        let queryWithTypo = BookSearchQuery(title: "はらぺこあおうし")  // "む" → "う"
        let score = scorer.calculateScore(searchQuery: queryWithTypo, book: book)
        
        // 類似度により中程度のスコアを期待
        #expect(score >= 0.3)
        #expect(score < 0.7)
    }
    
    @Test("完全に異なる文字列の低スコア")
    func testCompletelyDifferentStrings() {
        let query = BookSearchQuery(title: "xyz", author: "abc")
        let book = sampleBooks[0]  // "ぐりとぐら" by "なかがわりえこ"
        
        let score = scorer.calculateScore(searchQuery: query, book: book)
        
        // 完全に異なるので非常に低いスコアを期待
        #expect(score < 0.1)
    }
}

// MARK: - Scored Book Tests

@Suite("ScoredBook Tests")
struct ScoredBookTests {
    @Test("ScoredBookの作成と比較")
    func testScoredBookCreationAndComparison() {
        let book = Book(
            title: "Test Book",
            author: "Test Author",
            targetAge: 3
        )
        
        let scoredBook1 = ScoredBook(book: book, score: 0.8)
        let scoredBook2 = ScoredBook(book: book, score: 0.8)
        
        #expect(scoredBook1 == scoredBook2)
        #expect(scoredBook1.book == book)
        #expect(scoredBook1.score == 0.8)
    }
}

// MARK: - BookSearchQuery Tests

@Suite("BookSearchQuery Tests")
struct BookSearchQueryTests {
    @Test("BookSearchQueryの作成と比較")
    func testBookSearchQueryCreationAndComparison() {
        let query1 = BookSearchQuery(title: "テストタイトル", author: "テスト著者")
        let query2 = BookSearchQuery(title: "テストタイトル", author: "テスト著者")
        let query3 = BookSearchQuery(title: "テストタイトル")  // author なし
        
        #expect(query1 == query2)
        #expect(query1 != query3)
        #expect(query1.title == "テストタイトル")
        #expect(query1.author == "テスト著者")
        #expect(query3.author == nil)
    }
}
