import SwiftUI
import PictureBookLendingCore

/**
 * 絵本一覧表示ビュー
 *
 * 登録されている全ての絵本を一覧表示し、新規追加、編集、削除などの操作を提供します。
 */
struct BookListView: View {
    @Environment(\.bookModel) private var bookModel
    
    // 絵本の検索文字列
    @State private var searchText = ""
    
    // 新規絵本追加用のシート表示状態
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                if let books = bookModel?.getAllBooks(), !books.isEmpty {
                    ForEach(filteredBooks(books)) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
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
                BookFormView(mode: .add)
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
    
    // 絵本の削除処理
    private func deleteBooks(at offsets: IndexSet) {
        guard let books = bookModel?.getAllBooks() else { return }
        
        for index in offsets {
            let book = books[index]
            do {
                _ = try bookModel?.deleteBook(book.id)
            } catch {
                print("絵本の削除に失敗しました: \(error)")
            }
        }
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
    BookListView()
}