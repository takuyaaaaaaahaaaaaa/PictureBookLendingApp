import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 絵本一覧のContainer View
struct BookListContainerView: View {
    @Environment(BookModel.self) private var bookModel
    
    @State private var searchText = ""
    @State private var isAddSheetPresented = false
    @State private var alertState = AlertState()
    
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return bookModel.books
        } else {
            return bookModel.books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                    book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            BookListView(
                books: filteredBooks,
                searchText: $searchText,
                onDelete: handleDeleteBooks
            )
            .navigationTitle("絵本一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddSheetPresented = true
                    }) {
                        Label("絵本を追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddSheetPresented) {
                Text("絵本追加フォーム")
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
    
    return BookListContainerView()
        .environment(bookModel)
}
