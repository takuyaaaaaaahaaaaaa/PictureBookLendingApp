import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 絵本一覧のContainer View
///
/// 全絵本（貸出可能・貸出中を含む）を表示し、
/// 状態に応じて貸出・返却ボタンを提供します。
struct BookListContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(LoanModel.self) private var loanModel
    
    @State private var searchText = ""
    @State private var isSettingsPresented = false
    @State private var alertState = AlertState()
    
    private var filteredBooks: [Book] {
        // 全絵本を表示（貸出可能・貸出中を含む）
        let allBooks = bookModel.books
        
        // 検索テキストでフィルタリング
        return if searchText.isEmpty {
            allBooks
        } else {
            allBooks.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText)
                    || book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        BookListView(
            books: filteredBooks,
            searchText: $searchText,
            onDelete: handleDeleteBooks
        ) { book in
            LoanActionContainerButton(bookId: book.id)
        }
        .navigationTitle("絵本")
        .searchable(text: $searchText, prompt: "タイトル・著者で検索")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // 設定ボタン
                SettingContainerButton()
            }
        }
        .navigationDestination(for: Book.self) { book in
            BookDetailContainerView(book: book)
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .onAppear {
            bookModel.refreshBooks()
        }
        .refreshable {
            bookModel.refreshBooks()
        }
    }
    
    // MARK: - Actions
    
    private func handleDeleteBooks(at offsets: IndexSet) {
        for index in offsets {
            let book = filteredBooks[index]
            do {
                _ = try bookModel.deleteBook(book.id)
            } catch {
                alertState = .error("絵本の削除に失敗しました: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    
    // プレビュー用のサンプルデータを追加
    let book1 = Book(title: "はらぺこあおむし", author: "エリック・カール")
    let book2 = Book(title: "ぐりとぐら", author: "中川李枝子")
    _ = try? mockFactory.bookRepository.save(book1)
    _ = try? mockFactory.bookRepository.save(book2)
    
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let loanModel = LoanModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository,
        loanSettingsRepository: mockFactory.loanSettingsRepository
    )
    
    return BookListContainerView()
        .environment(bookModel)
        .environment(loanModel)
}
