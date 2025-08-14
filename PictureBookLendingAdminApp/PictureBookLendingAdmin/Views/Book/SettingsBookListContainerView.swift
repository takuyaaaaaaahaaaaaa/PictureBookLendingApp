import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 設定画面用の絵本一覧Container View
///
/// 絵本の管理機能に特化し、貸出ボタンの代わりに貸出状況を表示します。
struct SettingsBookListContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(LoanModel.self) private var loanModel
    
    @State private var searchText = ""
    @State private var isAddSheetPresented = false
    @State private var editingBook: Book?
    @State private var isEditMode = false
    @State private var alertState = AlertState()
    
    private var filteredBooks: [Book] {
        return if searchText.isEmpty {
            bookModel.books
        } else {
            bookModel.books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText)
                    || book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        BookListView(
            books: filteredBooks,
            searchText: $searchText,
            isEditMode: isEditMode,
            onSelect: handleSelectBook,
            onEdit: handleEditBook,
            onDelete: handleDeleteBooks
        ) { book in
            BookStatusView(isCurrentlyLent: loanModel.isBookLent(bookId: book.id))
        }
        .navigationTitle("絵本管理")
        .navigationDestination(for: Book.self) { book in
            BookDetailContainerView(book: book)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(isEditMode ? "完了" : "編集") {
                    isEditMode.toggle()
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isAddSheetPresented = true
                }) {
                    Label("絵本を追加", systemImage: "plus")
                }
            }
        }
        #if os(macOS)
            .sheet(isPresented: $isAddSheetPresented) {
                BookFormContainerView(
                    mode: .add,
                    onSave: { _ in
                        // 追加成功時にシートを閉じる処理は既にContainerView内で実行される
                    }
                )
            }
            .sheet(item: $editingBook) { book in
                BookFormContainerView(
                    mode: .edit(book),
                    onSave: { _ in
                        // 編集成功時にシートを閉じる処理は既にContainerView内で実行される
                    }
                )
            }
        #else
            .fullScreenCover(isPresented: $isAddSheetPresented) {
                BookFormContainerView(
                    mode: .add,
                    onSave: { _ in
                        // 追加成功時にシートを閉じる処理は既にContainerView内で実行される
                    }
                )
            }
            .fullScreenCover(item: $editingBook) { book in
                BookFormContainerView(
                    mode: .edit(book),
                    onSave: { _ in
                        // 編集成功時にシートを閉じる処理は既にContainerView内で実行される
                    }
                )
            }
        #endif
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .onAppear {
            bookModel.refreshBooks()
            loanModel.refreshLoans()
        }
        .refreshable {
            bookModel.refreshBooks()
            loanModel.refreshLoans()
        }
    }
    
    // MARK: - Actions
    
    private func handleSelectBook(_ book: Book) {
        // 絵本詳細画面に遷移（NavigationLinkで自動的に処理される）
    }
    
    private func handleEditBook(_ book: Book) {
        editingBook = book
    }
    
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
    
    return SettingsBookListContainerView()
        .environment(bookModel)
        .environment(loanModel)
}
