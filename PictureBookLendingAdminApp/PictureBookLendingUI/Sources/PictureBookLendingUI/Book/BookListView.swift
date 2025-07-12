import PictureBookLendingDomain
import SwiftUI

/**
 * 絵本一覧のPresentation View
 *
 * 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
 * 画面制御はContainer Viewに委譲します。
 */
public struct BookListView: View {
    let books: [Book]
    let searchText: Binding<String>
    let onDelete: (IndexSet) -> Void

    public init(
        books: [Book],
        searchText: Binding<String>,
        onDelete: @escaping (IndexSet) -> Void
    ) {
        self.books = books
        self.searchText = searchText
        self.onDelete = onDelete
    }

    public var body: some View {
        if books.isEmpty {
            ContentUnavailableView(
                "絵本がありません",
                systemImage: "book.closed",
                description: Text("右上の＋ボタンから絵本を追加してください")
            )
        } else {
            List {
                ForEach(books) { book in
                    NavigationLink(value: book) {
                        BookRowView(book: book)
                    }
                }
                .onDelete(perform: onDelete)
            }
            .searchable(text: searchText, prompt: "絵本のタイトルまたは著者で検索")
        }
    }
}

/**
 * 絵本リスト行ビュー
 *
 * 一覧の各行に表示する絵本情報のレイアウトを定義します。
 */
public struct BookRowView: View {
    let book: Book

    public var body: some View {
        VStack(alignment: .leading) {
            Text(book.title)
                .font(.headline)
            Text(book.author)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let book1 = Book(title: "はらぺこあおむし", author: "エリック・カール")
    let book2 = Book(title: "ぐりとぐら", author: "中川李枝子")

    NavigationStack {
        BookListView(
            books: [book1, book2],
            searchText: .constant(""),
            onDelete: { _ in }
        )
        .navigationTitle("絵本一覧")
    }
}
