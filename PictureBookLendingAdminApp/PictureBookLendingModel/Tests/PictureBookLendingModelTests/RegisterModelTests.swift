import Foundation
import PictureBookLendingDomain
import Testing

@testable import PictureBookLendingModel

@Suite("RegisterModel Tests")
struct RegisterModelTests {
    
    // MARK: - Test Data
    
    private let sampleBooks = [
        Book(
            title: "ぐりとぐら",
            author: "なかがわりえこ",
            isbn13: "9784834000825",
            publisher: "福音館書店",
            publishedDate: "1967-01-20",
            description: "森で大きな卵を見つけたぐりとぐら...",
            smallThumbnail: nil,
            thumbnail: nil,
            targetAge: 3,
            pageCount: 28,
            categories: ["絵本", "児童書"]
        ),
        Book(
            title: "ぐりとぐらのおきゃくさま",
            author: "なかがわりえこ",
            isbn13: "9784834001839",
            publisher: "福音館書店",
            publishedDate: "1967-06-01",
            description: "雪の日にぐりとぐらが見つけた足跡...",
            smallThumbnail: nil,
            thumbnail: nil,
            targetAge: 3,
            pageCount: 28,
            categories: ["絵本", "児童書"]
        ),
    ]
    
    // MARK: - Initialization Tests
    
    @Test("RegisterModelの初期化")
    @MainActor
    func testInitialization() {
        let model = createRegisterModel()
        
        #expect(model.searchTitle == "")
        #expect(model.searchAuthor == "")
        #expect(model.searchResults.isEmpty)
        #expect(model.selectedResult == nil)
        #expect(model.isManualEntryMode == false)
        #expect(model.manualBook == nil)
        #expect(model.isSearching == false)
        #expect(model.isRegistering == false)
        #expect(model.canSearch == false)  // タイトル・著者が両方空なので
        #expect(model.canRegister == false)  // 選択結果がないので
    }
    
    // MARK: - Search Input Tests
    
    @Test("検索実行可能性の判定")
    @MainActor
    func testCanSearch() {
        let model = createRegisterModel()
        
        // 初期状態：検索不可
        #expect(model.canSearch == false)
        
        // タイトル入力後：検索可能
        model.searchTitle = "ぐりとぐら"
        #expect(model.canSearch == true)
        
        // 著者のみ入力：検索可能
        model.searchTitle = ""
        model.searchAuthor = "なかがわりえこ"
        #expect(model.canSearch == true)
        
        // 空白のみ：検索不可
        model.searchTitle = "   "
        model.searchAuthor = "   "
        #expect(model.canSearch == false)
        
        // どちらか一方が有効なら検索可能
        model.searchTitle = ""
        model.searchAuthor = "なかがわりえこ"
        #expect(model.canSearch == true)
        
        // 検索中：検索不可
        model.searchTitle = "ぐりとぐら"
        model.searchAuthor = ""
        // isSearching = true をシミュレート（実際のテストではモックが必要）
        #expect(model.canSearch == true)  // 現在は検索中ではないので
    }
    
    // MARK: - Search Results Tests
    
    @Test("検索結果の選択")
    @MainActor
    func testSelectSearchResult() {
        let model = createRegisterModel()
        let scoredBook = ScoredBook(book: sampleBooks[0], score: 0.9)
        
        model.selectSearchResult(scoredBook)
        
        #expect(model.selectedResult == scoredBook)
        #expect(model.isManualEntryMode == false)
        #expect(model.canRegister == true)
    }
    
    @Test("検索結果のクリア")
    @MainActor
    func testClearSearchResults() {
        let model = createRegisterModel()
        
        // 検索結果を設定
        model.searchResults = [ScoredBook(book: sampleBooks[0], score: 0.9)]
        model.selectedResult = model.searchResults.first
        model.searchError = "テストエラー"
        
        model.clearSearchResults()
        
        #expect(model.searchResults.isEmpty)
        #expect(model.selectedResult == nil)
        #expect(model.searchError == nil)
    }
    
    // MARK: - Manual Entry Tests
    
    @Test("手動入力モードへの切り替え")
    @MainActor
    func testSwitchToManualEntry() {
        let model = createRegisterModel()
        
        // 検索入力を設定
        model.searchTitle = "テストタイトル"
        model.searchAuthor = "テスト著者"
        
        // 検索結果を選択済みの状態
        model.selectedResult = ScoredBook(book: sampleBooks[0], score: 0.9)
        
        model.switchToManualEntry()
        
        #expect(model.isManualEntryMode == true)
        #expect(model.selectedResult == nil)
        #expect(model.manualBook != nil)
        #expect(model.manualBook?.title == "テストタイトル")
        #expect(model.manualBook?.author == "テスト著者")
        #expect(model.canRegister == true)
    }
    
    @Test("手動入力モードで著者が空の場合")
    @MainActor
    func testSwitchToManualEntryWithEmptyAuthor() {
        let model = createRegisterModel()
        
        model.searchTitle = "テストタイトル"
        model.searchAuthor = ""
        
        model.switchToManualEntry()
        
        #expect(model.manualBook?.author == "不明")
    }
    
    @Test("検索結果モードへの切り替え")
    @MainActor
    func testSwitchToSearchResults() {
        let model = createRegisterModel()
        
        // 手動入力モードに設定
        model.switchToManualEntry()
        #expect(model.isManualEntryMode == true)
        #expect(model.manualBook != nil)
        
        model.switchToSearchResults()
        
        #expect(model.isManualEntryMode == false)
        #expect(model.manualBook == nil)
    }
    
    @Test("手動入力の絵本情報更新")
    @MainActor
    func testUpdateManualBook() {
        let model = createRegisterModel()
        let updatedBook = sampleBooks[0]
        
        model.updateManualBook(updatedBook)
        
        #expect(model.manualBook == updatedBook)
    }
    
    // MARK: - Registration Tests
    
    @Test("登録実行可能性の判定")
    @MainActor
    func testCanRegister() {
        let model = createRegisterModel()
        
        // 初期状態：登録不可
        #expect(model.canRegister == false)
        
        // 検索結果選択後：登録可能
        model.selectedResult = ScoredBook(book: sampleBooks[0], score: 0.9)
        #expect(model.canRegister == true)
        
        // 手動入力モード：登録可能
        model.selectedResult = nil
        model.switchToManualEntry()
        #expect(model.canRegister == true)
    }
    
    @Test("登録対象の絵本取得")
    @MainActor
    func testBookToRegister() {
        let model = createRegisterModel()
        
        // 初期状態：登録対象なし
        #expect(model.bookToRegister == nil)
        
        // 検索結果選択時
        model.selectedResult = ScoredBook(book: sampleBooks[0], score: 0.9)
        #expect(model.bookToRegister == sampleBooks[0])
        
        // 手動入力モード時
        model.switchToManualEntry()
        #expect(model.bookToRegister != nil)
        #expect(model.bookToRegister?.title != sampleBooks[0].title)  // 手動入力の本が返される
    }
    
    // MARK: - State Management Tests
    
    @Test("登録状態のリセット")
    @MainActor
    func testResetRegistrationState() {
        let model = createRegisterModel()
        
        // 各種状態を設定
        model.searchTitle = "テストタイトル"
        model.searchAuthor = "テスト著者"
        model.searchResults = [ScoredBook(book: sampleBooks[0], score: 0.9)]
        model.selectedResult = model.searchResults.first
        model.switchToManualEntry()
        model.searchError = "検索エラー"
        model.registrationError = "登録エラー"
        
        model.resetRegistrationState()
        
        #expect(model.searchTitle == "")
        #expect(model.searchAuthor == "")
        #expect(model.searchResults.isEmpty)
        #expect(model.selectedResult == nil)
        #expect(model.isManualEntryMode == false)
        #expect(model.manualBook == nil)
        #expect(model.searchError == nil)
        #expect(model.registrationError == nil)
    }
    
    // MARK: - Search Analysis Tests
    
    @Test("検索分析の取得")
    @MainActor
    func testGetSearchAnalysis() {
        let model = createRegisterModel()
        
        // 検索結果なしの場合
        #expect(model.getSearchAnalysis() == nil)
        
        // 検索結果ありの場合
        model.searchTitle = "ぐりとぐら"
        model.searchAuthor = "なかがわりえこ"
        model.searchResults = [
            ScoredBook(book: sampleBooks[0], score: 0.9),  // high score
            ScoredBook(book: sampleBooks[1], score: 0.6),  // medium score
        ]
        
        let analysis = model.getSearchAnalysis()
        
        #expect(analysis != nil)
        #expect(analysis?.totalResults == 2)
        #expect(analysis?.highScoreCount == 1)
        #expect(analysis?.mediumScoreCount == 1)
        #expect(analysis?.lowScoreCount == 0)
        #expect(analysis?.hasExactMatch == true)  // 0.9は0.9以上なので exact match
        #expect(analysis?.searchQuality == .excellent)
        #expect(analysis?.topResult?.score == 0.9)
    }
    
    @Test("検索品質の評価")
    @MainActor
    func testSearchQuality() {
        // excellent: 0.9以上の結果がある
        let excellentAnalysis = SearchAnalysis(
            searchQuery: BookSearchQuery(title: "test"),
            totalResults: 1,
            highScoreCount: 1,
            mediumScoreCount: 0,
            lowScoreCount: 0,
            hasExactMatch: true,
            averageScore: 0.95,
            topResult: ScoredBook(book: sampleBooks[0], score: 0.95)
        )
        #expect(excellentAnalysis.searchQuality == .excellent)
        
        // good: 0.8以上の結果がある
        let goodAnalysis = SearchAnalysis(
            searchQuery: BookSearchQuery(title: "test"),
            totalResults: 1,
            highScoreCount: 1,
            mediumScoreCount: 0,
            lowScoreCount: 0,
            hasExactMatch: false,
            averageScore: 0.85,
            topResult: ScoredBook(book: sampleBooks[0], score: 0.85)
        )
        #expect(goodAnalysis.searchQuality == .good)
        
        // fair: 0.5以上の結果がある
        let fairAnalysis = SearchAnalysis(
            searchQuery: BookSearchQuery(title: "test"),
            totalResults: 1,
            highScoreCount: 0,
            mediumScoreCount: 1,
            lowScoreCount: 0,
            hasExactMatch: false,
            averageScore: 0.6,
            topResult: ScoredBook(book: sampleBooks[0], score: 0.6)
        )
        #expect(fairAnalysis.searchQuality == .fair)
        
        // poor: 低スコアのみ
        let poorAnalysis = SearchAnalysis(
            searchQuery: BookSearchQuery(title: "test"),
            totalResults: 1,
            highScoreCount: 0,
            mediumScoreCount: 0,
            lowScoreCount: 1,
            hasExactMatch: false,
            averageScore: 0.3,
            topResult: ScoredBook(book: sampleBooks[0], score: 0.3)
        )
        #expect(poorAnalysis.searchQuality == .poor)
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func createRegisterModel() -> RegisterModel {
        let mockGateway = MockBookSearchGateway()
        let normalizer = MockStringNormalizer()
        let repository = MockBookRepository()
        
        return RegisterModel(
            gateway: mockGateway,
            normalizer: normalizer,
            repository: repository
        )
    }
}

// MARK: - Mock Objects

private struct MockBookSearchGateway: BookSearchGatewayProtocol {
    func searchBooks(title: String, author: String?, maxResults: Int) async throws -> [Book] {
        // テスト用の簡単な実装
        return []
    }
    
    func searchBook(by isbn: String) async throws -> Book {
        throw BookMetadataGatewayError.bookNotFound
    }
}

private struct MockStringNormalizer: StringNormalizer {
    func normalize(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespaces)
    }
    
    func normalizeTitle(_ title: String) -> String {
        return normalize(title)
    }
    
    func normalizeAuthor(_ author: String) -> String {
        return normalize(author)
    }
}
