import SwiftUI
import PictureBookLendingInfrastructure
import PictureBookLendingDomain
import PictureBookLendingModel

/**
 * 絵本一覧表示ビュー
 *
 * 登録されている全ての絵本を一覧表示し、新規追加、編集、削除などの操作を提供します。
 */
struct BookListView: View {
    let bookModel: BookModel
    
    // 絵本の検索文字列
    @State private var searchText = ""
    
    // 新規絵本追加用のシート表示状態
    @State private var showingAddSheet = false
    
    // 現在の絵本リスト
    @State private var books: [Book] = []
    
    var body: some View {
        NavigationStack {
            List {
                if !books.isEmpty {
                    ForEach(filteredBooks(books)) { book in
                        NavigationLink(destination: BookDetailView(bookModel: bookModel, book: book)) {
                            BookRowView(book: book)
                        }
                    }
                    .onDelete(perform: deleteBooks)
                } else {
                    ContentUnavailableView("絵本がありません", systemImage: "book.closed", description: Text("右上の＋ボタンから絵本を追加してください"))
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
            .searchable(text: $searchText, prompt: "絵本のタイトルまたは著者で検索")
            .sheet(isPresented: $showingAddSheet) {
                BookFormView(bookModel: bookModel, mode: .add, onSave: { _ in
                    loadBooks()
                })
            }
            .onAppear {
                loadBooks()
            }
            .refreshable {
                loadBooks()
            }
        }
    }
    
    // 検索フィルタリング
    private func filteredBooks(_ books: [Book]) -> [Book] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // 書籍リストの読み込み
    private func loadBooks() {
        books = bookModel.getAllBooks()
    }
    
    // 絵本の削除処理
    private func deleteBooks(at offsets: IndexSet) {
        for index in offsets {
            let book = books[index]
            do {
                _ = try bookModel.deleteBook(book.id)
            } catch {
                print("絵本の削除に失敗しました: \(error)")
            }
        }
        loadBooks()
    }
}

/**
 * 絵本リスト行ビュー
 *
 * 一覧の各行に表示する絵本情報のレイアウトを定義します。
 */
struct BookRowView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(book.title)
                .font(.headline)
            Text(book.author)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
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
    return BookListView(bookModel: bookModel)
}