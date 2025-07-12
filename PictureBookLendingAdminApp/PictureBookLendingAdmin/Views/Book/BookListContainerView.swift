import SwiftUI
import PictureBookLendingInfrastructure
import PictureBookLendingDomain
import PictureBookLendingModel
import PictureBookLendingUI

/**
 * 絵本一覧のContainer View
 *
 * ビジネスロジック、状態管理、データ取得、画面制御を担当し、
 * Presentation ViewにデータとアクションHookを提供します。
 */
struct BookListContainerView: View {
    private let bookModel: BookModel
    
    @State private var books: [Book] = []
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var alertState = AlertState()
    @State private var loadingState = LoadingState.idle
    
    init(bookModel: BookModel) {
        self.bookModel = bookModel
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if loadingState.isLoading {
                    ProgressView(loadingState.message)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    BookListView(
                        books: filteredBooks,
                        searchText: $searchText,
                        onDelete: handleDeleteBooks
                    )
                }
            }
            .navigationTitle("絵本一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Label("絵本を追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                Text("絵本追加フォーム")
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertState.message)
            }
            .onAppear {
                loadBooks()
            }
            .refreshable {
                loadBooks()
            }
        }
        .task {
            await loadBooksAsync()
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadBooks() {
        books = bookModel.getAllBooks()
    }
    
    private func loadBooksAsync() async {
        loadingState = .loading
        await Task { @MainActor in
            loadBooks()
            loadingState = .idle
        }.value
    }
    
    private func handleDeleteBooks(at offsets: IndexSet) {
        for index in offsets {
            let book = filteredBooks[index]
            do {
                _ = try bookModel.deleteBook(book.id)
                loadBooks()
            } catch {
                alertState = .error("絵本の削除に失敗しました: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleAddBookSaved(_ book: Book) {
        loadBooks()
        showingAddSheet = false
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    
    // プレビュー用のサンプルデータを追加
    let book1 = Book(title: "はらぺこあおむし", author: "エリック・カール")
    let book2 = Book(title: "ぐりとぐら", author: "中川李枝子")
    try? mockFactory.bookRepository.save(book1)
    try? mockFactory.bookRepository.save(book2)
    
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    return BookListContainerView(bookModel: bookModel)
}
