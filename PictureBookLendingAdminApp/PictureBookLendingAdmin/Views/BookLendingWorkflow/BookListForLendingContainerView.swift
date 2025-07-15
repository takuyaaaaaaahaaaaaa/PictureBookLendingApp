import PictureBookLendingDomain
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出用絵本一覧のコンテナビュー
///
/// 貸出可能な絵本の一覧を表示し、選択した絵本から貸出ワークフローを開始します。
/// 検索・フィルタ機能を提供し、iPad横向きでの操作に最適化されています。
struct BookListForLendingContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var searchText = ""
    @State private var selectedFilter: BookFilter = .all
    @State private var alertState = AlertState()
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 検索・フィルタ UI
            SearchAndFilterBarView(
                searchText: $searchText,
                searchPlaceholder: "絵本タイトル・著者で検索",
                selectedFilter: $selectedFilter,
                filterOptions: BookFilter.allCases
            )
            
            // 絵本一覧
            if isLoading {
                LoadingView(message: "絵本を読み込み中...")
            } else {
                BookListView(
                    books: filteredBooks,
                    searchText: $searchText,
                    onSelect: handleBookSelection,
                    showLendingStatus: true,
                    displayMode: .grid
                )
            }
        }
        .refreshable {
            await loadBooks()
        }
        .task {
            await loadBooks()
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private var filteredBooks: [Book] {
        let searchFiltered = searchText.isEmpty ? bookModel.books : bookModel.books.filter { book in
            book.title.localizedCaseInsensitiveContains(searchText) ||
            book.author.localizedCaseInsensitiveContains(searchText)
        }
        
        return selectedFilter.apply(to: searchFiltered, lendingModel: lendingModel)
    }
    
    private func handleBookSelection(_ book: Book) {
        // 貸出中の絵本は選択不可
        if lendingModel.isBookCurrentlyLoaned(book.id) {
            alertState = AlertState(
                title: "この絵本は貸出中です",
                message: "「\(book.title)」は現在貸出中のため、新たに貸し出すことはできません。"
            )
            return
        }
        
        // NavigationStackで次の画面へ遷移
        // BookDetailForLendingContainerViewへの遷移はNavigationStackで処理される
    }
    
    private func loadBooks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await bookModel.load()
            try await lendingModel.load()
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "絵本データの読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 絵本フィルタ用列挙型
enum BookFilter: String, CaseIterable {
    case all = "すべて"
    case available = "貸出可能"
    case loaned = "貸出中"
    
    func apply(to books: [Book], lendingModel: LendingModel) -> [Book] {
        switch self {
        case .all:
            return books
        case .available:
            return books.filter { !lendingModel.isBookCurrentlyLoaned($0.id) }
        case .loaned:
            return books.filter { lendingModel.isBookCurrentlyLoaned($0.id) }
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    NavigationStack {
        BookListForLendingContainerView()
            .environment(bookModel)
            .environment(lendingModel)
    }
}