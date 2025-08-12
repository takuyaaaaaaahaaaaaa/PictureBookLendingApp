import Kingfisher
import PictureBookLendingDomain
import SwiftUI

/// 絵本検索のPresentation View
///
/// タイトル・著者による絵本検索、検索結果表示、手動入力切り替えを提供します。
/// 純粋なUI表示のみを担当し、状態管理はContainer Viewに委譲します。
public struct BookSearchView: View {
    
    // MARK: - Input Properties
    
    @Binding var searchTitle: String
    @Binding var searchAuthor: String
    let canSearch: Bool
    let isSearching: Bool
    let searchError: String?
    
    // MARK: - Search Results Properties
    
    let searchResults: [ScoredBook]
    let selectedResult: ScoredBook?
    let onResultSelected: (ScoredBook) -> Void
    
    // MARK: - Manual Entry Properties
    
    let isManualEntryMode: Bool
    let manualBook: Book?
    let onManualBookChanged: (Book) -> Void
    
    // MARK: - Actions
    
    let onSearch: () -> Void
    let onClearResults: () -> Void
    let onSwitchToManualEntry: () -> Void
    let onSwitchToSearchResults: () -> Void
    let onRegister: () -> Void
    
    // MARK: - State Properties
    
    let canRegister: Bool
    let isRegistering: Bool
    let registrationError: String?
    
    public init(
        searchTitle: Binding<String>,
        searchAuthor: Binding<String>,
        canSearch: Bool,
        isSearching: Bool,
        searchError: String?,
        searchResults: [ScoredBook],
        selectedResult: ScoredBook?,
        onResultSelected: @escaping (ScoredBook) -> Void,
        isManualEntryMode: Bool,
        manualBook: Book?,
        onManualBookChanged: @escaping (Book) -> Void,
        onSearch: @escaping () -> Void,
        onClearResults: @escaping () -> Void,
        onSwitchToManualEntry: @escaping () -> Void,
        onSwitchToSearchResults: @escaping () -> Void,
        onRegister: @escaping () -> Void,
        canRegister: Bool,
        isRegistering: Bool,
        registrationError: String?
    ) {
        self._searchTitle = searchTitle
        self._searchAuthor = searchAuthor
        self.canSearch = canSearch
        self.isSearching = isSearching
        self.searchError = searchError
        self.searchResults = searchResults
        self.selectedResult = selectedResult
        self.onResultSelected = onResultSelected
        self.isManualEntryMode = isManualEntryMode
        self.manualBook = manualBook
        self.onManualBookChanged = onManualBookChanged
        self.onSearch = onSearch
        self.onClearResults = onClearResults
        self.onSwitchToManualEntry = onSwitchToManualEntry
        self.onSwitchToSearchResults = onSwitchToSearchResults
        self.onRegister = onRegister
        self.canRegister = canRegister
        self.isRegistering = isRegistering
        self.registrationError = registrationError
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 検索入力セクション
            searchInputSection
            
            Divider()
            
            // メインコンテンツ
            if isManualEntryMode {
                manualEntrySection
            } else {
                searchResultsSection
            }
            
            Divider()
            
            // 登録ボタンセクション
            registrationSection
        }
        .navigationTitle("絵本を登録")
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var searchInputSection: some View {
        VStack(spacing: 16) {
            // 検索フォーム
            VStack(spacing: 12) {
                TextField("絵本のタイトルを入力", text: $searchTitle)
                    .textFieldStyle(.roundedBorder)
                
                TextField("著者名を入力（任意）", text: $searchAuthor)
                    .textFieldStyle(.roundedBorder)
            }
            
            // 検索ボタンと切り替えボタン
            HStack(spacing: 12) {
                Button("検索") {
                    onSearch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSearch)
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Spacer()
                
                // モード切り替えボタン
                Button(isManualEntryMode ? "検索結果から選択" : "手動で入力") {
                    if isManualEntryMode {
                        onSwitchToSearchResults()
                    } else {
                        onSwitchToManualEntry()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            // エラー表示
            if let searchError = searchError {
                Text(searchError)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    @ViewBuilder
    private var searchResultsSection: some View {
        if searchResults.isEmpty && !isSearching {
            ContentUnavailableView(
                "検索結果なし",
                systemImage: "magnifyingglass",
                description: Text("タイトルを入力して絵本を検索してください")
            )
        } else {
            List(searchResults, id: \.book.id) { scoredBook in
                SearchResultRow(
                    scoredBook: scoredBook,
                    isSelected: selectedResult?.book.id == scoredBook.book.id,
                    onTap: { onResultSelected(scoredBook) }
                )
            }
            .listStyle(.plain)
        }
    }
    
    @ViewBuilder
    private var manualEntrySection: some View {
        if let manualBook = manualBook {
            Form {
                Section("絵本情報") {
                    HStack {
                        Text("タイトル")
                            .foregroundStyle(.secondary)
                        TextField(
                            "タイトルを入力",
                            text: Binding(
                                get: { manualBook.title },
                                set: { newTitle in
                                    let updatedBook = Book(
                                        id: manualBook.id,
                                        title: newTitle,
                                        author: manualBook.author,
                                        isbn13: manualBook.isbn13,
                                        publisher: manualBook.publisher,
                                        publishedDate: manualBook.publishedDate,
                                        description: manualBook.description,
                                        smallThumbnail: manualBook.smallThumbnail,
                                        thumbnail: manualBook.thumbnail,
                                        targetAge: manualBook.targetAge,
                                        pageCount: manualBook.pageCount,
                                        categories: manualBook.categories
                                    )
                                    onManualBookChanged(updatedBook)
                                }
                            )
                        )
                        .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("著者")
                            .foregroundStyle(.secondary)
                        TextField(
                            "著者を入力",
                            text: Binding(
                                get: { manualBook.author },
                                set: { newAuthor in
                                    let updatedBook = Book(
                                        id: manualBook.id,
                                        title: manualBook.title,
                                        author: newAuthor,
                                        isbn13: manualBook.isbn13,
                                        publisher: manualBook.publisher,
                                        publishedDate: manualBook.publishedDate,
                                        description: manualBook.description,
                                        smallThumbnail: manualBook.smallThumbnail,
                                        thumbnail: manualBook.thumbnail,
                                        targetAge: manualBook.targetAge,
                                        pageCount: manualBook.pageCount,
                                        categories: manualBook.categories
                                    )
                                    onManualBookChanged(updatedBook)
                                }
                            )
                        )
                        .multilineTextAlignment(.trailing)
                    }
                    
                    EditableDetailRowWithSelection(
                        label: "対象年齢",
                        selectedValue: .constant(manualBook.targetAge ?? 3),
                        options: Array(1...10),
                        displayText: { "\($0)歳" },
                        onSelectionChanged: { newAge in
                            let updatedBook = Book(
                                id: manualBook.id,
                                title: manualBook.title,
                                author: manualBook.author,
                                isbn13: manualBook.isbn13,
                                publisher: manualBook.publisher,
                                publishedDate: manualBook.publishedDate,
                                description: manualBook.description,
                                smallThumbnail: manualBook.smallThumbnail,
                                thumbnail: manualBook.thumbnail,
                                targetAge: newAge,
                                pageCount: manualBook.pageCount,
                                categories: manualBook.categories
                            )
                            onManualBookChanged(updatedBook)
                        }
                    )
                }
            }
        } else {
            ContentUnavailableView(
                "手動入力準備中",
                systemImage: "square.and.pencil",
                description: Text("手動入力フォームを準備しています")
            )
        }
    }
    
    @ViewBuilder
    private var registrationSection: some View {
        VStack(spacing: 8) {
            if let registrationError = registrationError {
                Text(registrationError)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            Button("絵本を登録") {
                onRegister()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canRegister || isRegistering)
            .overlay {
                if isRegistering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
    }
}

/// 検索結果行コンポーネント
struct SearchResultRow: View {
    let scoredBook: ScoredBook
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // サムネイル画像
                KFImage(URL(string: scoredBook.book.thumbnail ?? scoredBook.book.smallThumbnail ?? ""))
                    .placeholder {
                        Image(systemName: "book.closed")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 80)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(scoredBook.book.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(scoredBook.book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let publisher = scoredBook.book.publisher {
                        Text(publisher)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // スコア表示
                    HStack {
                        Text("関連度:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(scoredBook.score * 100))%")
                            .font(.caption)
                            .foregroundStyle(scoreColor)
                            .fontWeight(.medium)
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .background(isSelected ? .blue.opacity(0.1) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var scoreColor: Color {
        switch scoredBook.score {
        case 0.8...:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

#Preview("Search Results") {
    NavigationStack {
        BookSearchView(
            searchTitle: .constant("ぐりとぐら"),
            searchAuthor: .constant("なかがわりえこ"),
            canSearch: true,
            isSearching: false,
            searchError: nil,
            searchResults: [
                ScoredBook(
                    book: Book(title: "ぐりとぐら", author: "なかがわりえこ", targetAge: 3),
                    score: 0.95
                ),
                ScoredBook(
                    book: Book(title: "ぐりとぐらのおきゃくさま", author: "なかがわりえこ", targetAge: 3),
                    score: 0.75
                ),
            ],
            selectedResult: nil,
            onResultSelected: { _ in },
            isManualEntryMode: false,
            manualBook: nil,
            onManualBookChanged: { _ in },
            onSearch: {},
            onClearResults: {},
            onSwitchToManualEntry: {},
            onSwitchToSearchResults: {},
            onRegister: {},
            canRegister: false,
            isRegistering: false,
            registrationError: nil
        )
    }
}

#Preview("Manual Entry") {
    NavigationStack {
        BookSearchView(
            searchTitle: .constant(""),
            searchAuthor: .constant(""),
            canSearch: false,
            isSearching: false,
            searchError: nil,
            searchResults: [],
            selectedResult: nil,
            onResultSelected: { _ in },
            isManualEntryMode: true,
            manualBook: Book(title: "テスタイトル", author: "テスト著者", targetAge: 4),
            onManualBookChanged: { _ in },
            onSearch: {},
            onClearResults: {},
            onSwitchToManualEntry: {},
            onSwitchToSearchResults: {},
            onRegister: {},
            canRegister: true,
            isRegistering: false,
            registrationError: nil
        )
    }
}

#Preview("Empty Search Form") {
    NavigationStack {
        BookSearchView(
            searchTitle: .constant(""),
            searchAuthor: .constant(""),
            canSearch: false,
            isSearching: false,
            searchError: nil,
            searchResults: [],
            selectedResult: nil,
            onResultSelected: { _ in },
            isManualEntryMode: false,
            manualBook: nil,
            onManualBookChanged: { _ in },
            onSearch: { print("Search pressed!") },
            onClearResults: {},
            onSwitchToManualEntry: {},
            onSwitchToSearchResults: {},
            onRegister: {},
            canRegister: false,
            isRegistering: false,
            registrationError: nil
        )
    }
}

#Preview("With Title Only") {
    NavigationStack {
        BookSearchView(
            searchTitle: .constant("ぐりとぐら"),
            searchAuthor: .constant(""),
            canSearch: true,
            isSearching: false,
            searchError: nil,
            searchResults: [],
            selectedResult: nil,
            onResultSelected: { _ in },
            isManualEntryMode: false,
            manualBook: nil,
            onManualBookChanged: { _ in },
            onSearch: { print("Search with title only pressed!") },
            onClearResults: {},
            onSwitchToManualEntry: {},
            onSwitchToSearchResults: {},
            onRegister: {},
            canRegister: false,
            isRegistering: false,
            registrationError: nil
        )
    }
}
