import PictureBookLendingDomain
import SwiftUI
import Kingfisher

/// 絵本一覧のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct BookListView<RowAction: View>: View {
    let books: [Book]
    let searchText: Binding<String>
    let onDelete: (IndexSet) -> Void
    let rowAction: (Book) -> RowAction
    
    public init(
        books: [Book],
        searchText: Binding<String>,
        onDelete: @escaping (IndexSet) -> Void,
        @ViewBuilder rowAction: @escaping (Book) -> RowAction
    ) {
        self.books = books
        self.searchText = searchText
        self.onDelete = onDelete
        self.rowAction = rowAction
    }
    
    public var body: some View {
        if books.isEmpty {
            ContentUnavailableView(
                "絵本が登録されていません",
                systemImage: "book.closed",
                description: Text("設定画面から絵本を登録してください")
            )
        } else {
            List {
                ForEach(books) { book in
                    NavigationLink(value: book) {
                        BookRowView(book: book, rowAction: rowAction)
                    }
                }
                .onDelete(perform: onDelete)
            }
            .searchable(text: searchText, prompt: "絵本のタイトルまたは著者で検索")
        }
    }
}

/// 絵本リスト行ビュー
///
/// 一覧の各行に表示する絵本情報のレイアウトを定義します。
public struct BookRowView<RowAction: View>: View {
    let book: Book
    let rowAction: (Book) -> RowAction
    
    public var body: some View {
        HStack {
            // サムネイル画像
            KFImage(URL(string: book.thumbnail ?? book.smallThumbnail ?? ""))
                .placeholder {
                    Image(systemName: "book.closed")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 65)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            rowAction(book)
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
        ) { book in
            LoanButtonView(onTap: {})
        }
        .navigationTitle("絵本一覧")
    }
}
