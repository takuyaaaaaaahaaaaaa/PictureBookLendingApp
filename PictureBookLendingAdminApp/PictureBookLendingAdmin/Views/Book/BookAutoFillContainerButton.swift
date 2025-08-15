import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 絵本自動入力ボタンのContainer View
///
/// RegisterModelを使用してビジネスロジックを処理し、
/// BookAutoFillButtonに状態とアクションを提供します。
struct BookAutoFillContainerButton: View {
    @Binding var targetBook: Book
    let onAutoFillComplete: (Book) -> Void
    
    @State private var registerModel: RegisterModel
    @State private var isResultSheetPresented = false
    
    init(targetBook: Binding<Book>, onAutoFillComplete: @escaping (Book) -> Void) {
        self._targetBook = targetBook
        self.onAutoFillComplete = onAutoFillComplete
        
        // RegisterModelを初期化
        let repositoryFactory = SwiftDataRepositoryFactory.shared
        let gateway = repositoryFactory.makeBookSearchGateway()
        let normalizer = GoogleBooksOptimizedNormalizer()
        let repository = repositoryFactory.makeBookRepository()
        
        self._registerModel = State(
            initialValue: RegisterModel(
                gateway: gateway,
                normalizer: normalizer,
                repository: repository
            )
        )
    }
    
    var body: some View {
        BookAutoFillButton(
            isSearching: registerModel.isSearching,
            searchError: registerModel.searchError,
            onSearch: handleSearch
        )
        .sheet(isPresented: $isResultSheetPresented) {
            searchResultsSheet
                .interactiveDismissDisabled()  // スワイプで閉じないように
        }
        .onChange(of: registerModel.searchResults) { _, newResults in
            if !newResults.isEmpty {
                isResultSheetPresented = true
            }
        }
    }
    
    @ViewBuilder
    private var searchResultsSheet: some View {
        BookSearchResultsView(
            searchResults: registerModel.searchResults,
            onBookSelect: selectBook,
            onCancel: {
                isResultSheetPresented = false
                registerModel.clearSearchResults()
            }
        )
    }
    
    // MARK: - Action Handlers
    
    private func handleSearch() {
        // BookFormViewのタイトルと著者名を使用して検索
        registerModel.searchTitle = targetBook.title
        registerModel.searchAuthor = targetBook.author ?? ""
        
        do {
            try registerModel.searchBooks()
        } catch {
            // エラーはregisterModel.searchErrorに設定される
        }
    }
    
    private func selectBook(_ book: Book) {
        // targetBookの既存値を保持しつつ、検索結果の情報で更新
        let updatedBook = Book(
            id: targetBook.id,  // 既存のIDを保持
            title: book.title.isEmpty ? targetBook.title : book.title,
            author: book.author?.isEmpty == false ? book.author : targetBook.author,
            isbn13: book.isbn13 ?? targetBook.isbn13,
            publisher: book.publisher ?? targetBook.publisher,
            publishedDate: book.publishedDate ?? targetBook.publishedDate,
            description: book.description ?? targetBook.description,
            smallThumbnail: book.smallThumbnail ?? targetBook.smallThumbnail,
            thumbnail: book.thumbnail ?? targetBook.thumbnail,
            targetAge: book.targetAge ?? targetBook.targetAge,
            pageCount: book.pageCount ?? targetBook.pageCount,
            categories: book.categories.isEmpty ? targetBook.categories : book.categories,
            managementNumber: targetBook.managementNumber  // 管理番号は既存値を保持
        )
        
        targetBook = updatedBook
        onAutoFillComplete(updatedBook)
        
        // UI状態をリセット
        isResultSheetPresented = false
        registerModel.clearSearchResults()
    }
}

#Preview {
    @Previewable @State var sampleBook = Book(
        title: "テスト絵本",
        author: "テスト著者"
    )
    
    BookAutoFillContainerButton(
        targetBook: $sampleBook,
        onAutoFillComplete: { book in
            print("Auto-filled book: \(book.title)")
        }
    )
    .padding()
}
