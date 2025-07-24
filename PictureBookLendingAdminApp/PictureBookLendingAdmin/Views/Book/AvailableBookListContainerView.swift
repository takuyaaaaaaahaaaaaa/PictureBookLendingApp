import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出可能絵本一覧のContainer View
struct AvailableBookListContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(LoanModel.self) private var loanModel
    
    @State private var searchText = ""
    @State private var isAddSheetPresented = false
    @State private var isSettingsPresented = false
    @State private var alertState = AlertState()
    
    private var filteredBooks: [Book] {
        // 貸出可能な絵本のみをフィルタリング
        let availableBooks = bookModel.books.filter { book in
            !loanModel.isBookLent(bookId: book.id)
        }
        
        // 検索テキストでさらにフィルタリング
        return if searchText.isEmpty {
            availableBooks
        } else {
            availableBooks.filter { book in
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
            LoanActionContainerButton(book: book)
        }
        .navigationTitle("貸出")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("設定", systemImage: "gearshape") {
                    isSettingsPresented = true
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsContainerView()
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
    
    return AvailableBookListContainerView()
        .environment(bookModel)
        .environment(loanModel)
}
