import Foundation
import Observation
import PictureBookLendingDomain

/// 絵本登録に関するエラー
public enum RegisterModelError: Error, Equatable, LocalizedError {
    /// 検索に失敗した場合のエラー
    case searchFailed
    /// 登録に失敗した場合のエラー
    case registrationFailed
    /// ネットワークエラー
    case networkError
    /// 不明なエラー
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .searchFailed:
            return "絵本の検索に失敗しました"
        case .registrationFailed:
            return "絵本の登録に失敗しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .unknown:
            return "不明なエラーが発生しました"
        }
    }
}

/// 絵本登録モデル
///
/// タイトル・著者入力による絵本検索と登録機能を提供します。
/// 検索結果のスコアリング、手動入力との切り替え、登録状態管理を担当します。
@Observable
@MainActor
public class RegisterModel {
    
    // MARK: - Dependencies
    
    private let gateway: BookSearchGatewayProtocol
    private let scorer: BookSearchScorer
    private let normalizer: StringNormalizer
    private let repository: BookRepositoryProtocol
    
    // MARK: - Observable Properties
    
    /// 検索入力状態
    public var searchTitle: String = ""
    public var searchAuthor: String = ""
    
    /// 検索結果
    public var searchResults: [ScoredBook] = []
    public var isSearching: Bool = false
    public var searchError: String?
    
    /// 選択された検索結果
    public var selectedResult: ScoredBook?
    
    /// 手動入力モードの状態
    public var isManualEntryMode: Bool = false
    public var manualBook: Book?
    
    /// 登録状態
    public var isRegistering: Bool = false
    public var registrationError: String?
    
    // MARK: - Computed Properties
    
    /// 検索実行可能かどうか
    public var canSearch: Bool {
        let hasTitleInput = !searchTitle.trimmingCharacters(in: .whitespaces).isEmpty
        let hasAuthorInput = !searchAuthor.trimmingCharacters(in: .whitespaces).isEmpty
        let result = (hasTitleInput || hasAuthorInput) && !isSearching
        
        #if DEBUG
            print("🔍 canSearch check:")
            print("  - searchTitle: '\(searchTitle)'")
            print("  - searchAuthor: '\(searchAuthor)'")
            print("  - hasTitleInput: \(hasTitleInput)")
            print("  - hasAuthorInput: \(hasAuthorInput)")
            print("  - isSearching: \(isSearching)")
            print("  - result: \(result)")
        #endif
        
        return result
    }
    
    /// 登録実行可能かどうか
    public var canRegister: Bool {
        !isRegistering && (selectedResult != nil || manualBook != nil)
    }
    
    /// 現在の登録対象の絵本
    public var bookToRegister: Book? {
        if isManualEntryMode {
            return manualBook
        } else {
            return selectedResult?.book
        }
    }
    
    // MARK: - Initialization
    
    public init(
        gateway: BookSearchGatewayProtocol,
        scorer: BookSearchScorer = BookSearchScorer(),
        normalizer: StringNormalizer,
        repository: BookRepositoryProtocol
    ) {
        self.gateway = gateway
        self.scorer = scorer
        self.normalizer = normalizer
        self.repository = repository
    }
    
    // MARK: - Search Actions
    
    /// タイトル・著者検索を実行
    public func searchBooks() throws {
        guard canSearch else { return }
        
        isSearching = true
        searchError = nil
        
        Task {
            do {
                // 入力値の正規化
                let normalizedTitle =
                    searchTitle.isEmpty ? "" : normalizer.normalizeTitle(searchTitle)
                let normalizedAuthor =
                    searchAuthor.isEmpty ? nil : normalizer.normalizeAuthor(searchAuthor)
                
                // Gateway経由で検索実行
                let books = try await gateway.searchBooks(
                    title: normalizedTitle,
                    author: normalizedAuthor,
                    maxResults: 20
                )
                
                // 検索クエリを作成（元の入力値でスコアリング）
                let searchQuery = BookSearchQuery(
                    title: searchTitle.isEmpty ? "" : searchTitle,
                    author: searchAuthor.isEmpty ? nil : searchAuthor
                )
                
                // スコアリング実行
                let scoredBooks = scorer.scoreSearchResults(
                    searchQuery: searchQuery,
                    books: books
                )
                
                searchResults = scoredBooks
                
            } catch {
                searchError = handleSearchError(error)
            }
            
            isSearching = false
        }
    }
    
    /// 検索結果をクリア
    public func clearSearchResults() {
        searchResults = []
        selectedResult = nil
        searchError = nil
    }
    
    /// 検索結果を選択
    public func selectSearchResult(_ result: ScoredBook) {
        selectedResult = result
        isManualEntryMode = false
    }
    
    // MARK: - Manual Entry Actions
    
    /// 手動入力モードに切り替え
    public func switchToManualEntry() {
        isManualEntryMode = true
        selectedResult = nil
        
        // 検索入力をベースに手動入力の初期値を設定
        if manualBook == nil {
            manualBook = Book(
                title: searchTitle.isEmpty ? "" : searchTitle,
                author: searchAuthor.isEmpty ? "不明" : searchAuthor,
                isbn13: nil,
                publisher: nil,
                publishedDate: nil,
                description: nil,
                smallThumbnail: nil,
                thumbnail: nil,
                targetAge: 3,  // デフォルト対象年齢
                pageCount: nil,
                categories: [],
                managementNumber: ""
            )
        }
    }
    
    /// 検索結果モードに切り替え
    public func switchToSearchResults() {
        isManualEntryMode = false
        manualBook = nil
    }
    
    /// 手動入力の絵本情報を更新
    public func updateManualBook(_ book: Book) {
        manualBook = book
    }
    
    // MARK: - Registration Actions
    
    /// 絵本を登録
    public func registerBook() throws -> Book {
        guard canRegister, let book = bookToRegister else {
            throw RegisterModelError.registrationFailed
        }
        
        isRegistering = true
        registrationError = nil
        
        do {
            let savedBook = try repository.save(book)
            
            // 登録成功後のクリーンアップ
            resetRegistrationState()
            isRegistering = false
            
            return savedBook
            
        } catch {
            isRegistering = false
            registrationError = handleRegistrationError(error)
            throw RegisterModelError.registrationFailed
        }
    }
    
    // MARK: - State Management
    
    /// 登録状態をリセット
    public func resetRegistrationState() {
        searchTitle = ""
        searchAuthor = ""
        searchResults = []
        selectedResult = nil
        isManualEntryMode = false
        manualBook = nil
        searchError = nil
        registrationError = nil
    }
    
    /// 検索分析を取得
    public func getSearchAnalysis() -> SearchAnalysis? {
        guard !searchResults.isEmpty else { return nil }
        
        let query = BookSearchQuery(
            title: searchTitle,
            author: searchAuthor.isEmpty ? nil : searchAuthor
        )
        
        let highScoreCount = searchResults.filter { $0.score >= 0.8 }.count
        let mediumScoreCount = searchResults.filter { $0.score >= 0.5 && $0.score < 0.8 }.count
        let lowScoreCount = searchResults.filter { $0.score < 0.5 }.count
        
        let hasExactMatch = searchResults.first?.score ?? 0.0 >= 0.9
        let averageScore = searchResults.map { $0.score }.reduce(0, +) / Double(searchResults.count)
        
        return SearchAnalysis(
            searchQuery: query,
            totalResults: searchResults.count,
            highScoreCount: highScoreCount,
            mediumScoreCount: mediumScoreCount,
            lowScoreCount: lowScoreCount,
            hasExactMatch: hasExactMatch,
            averageScore: averageScore,
            topResult: searchResults.first
        )
    }
    
    // MARK: - Private Methods
    
    private func handleSearchError(_ error: Error) -> String {
        if let gatewayError = error as? BookMetadataGatewayError {
            switch gatewayError {
            case .bookNotFound:
                return "指定された条件で絵本が見つかりませんでした"
            case .networkError:
                return "ネットワークエラーが発生しました"
            case .decodingError:
                return "検索結果の処理中にエラーが発生しました"
            case .httpError(let statusCode):
                return "サーバーエラーが発生しました（\(statusCode)）"
            case .invalidISBN:
                return "無効なISBNです"
            case .unknown:
                return "不明なエラーが発生しました"
            }
        }
        return "検索中にエラーが発生しました: \(error.localizedDescription)"
    }
    
    private func handleRegistrationError(_ error: Error) -> String {
        return "絵本の登録中にエラーが発生しました: \(error.localizedDescription)"
    }
}

/// 検索結果の分析データ
public struct SearchAnalysis: Equatable, Sendable {
    public let searchQuery: BookSearchQuery
    public let totalResults: Int
    public let highScoreCount: Int  // 0.8以上
    public let mediumScoreCount: Int  // 0.5-0.8
    public let lowScoreCount: Int  // 0.5未満
    public let hasExactMatch: Bool  // 0.9以上の結果があるか
    public let averageScore: Double
    public let topResult: ScoredBook?
    
    public init(
        searchQuery: BookSearchQuery,
        totalResults: Int,
        highScoreCount: Int,
        mediumScoreCount: Int,
        lowScoreCount: Int,
        hasExactMatch: Bool,
        averageScore: Double,
        topResult: ScoredBook?
    ) {
        self.searchQuery = searchQuery
        self.totalResults = totalResults
        self.highScoreCount = highScoreCount
        self.mediumScoreCount = mediumScoreCount
        self.lowScoreCount = lowScoreCount
        self.hasExactMatch = hasExactMatch
        self.averageScore = averageScore
        self.topResult = topResult
    }
    
    /// 検索品質の評価
    public var searchQuality: SearchQuality {
        if hasExactMatch {
            return .excellent
        } else if highScoreCount > 0 {
            return .good
        } else if mediumScoreCount > 0 {
            return .fair
        } else {
            return .poor
        }
    }
}

/// 検索品質の評価
public enum SearchQuality: String, CaseIterable, Sendable {
    case excellent = "非常に良い"
    case good = "良い"
    case fair = "普通"
    case poor = "悪い"
}
