import Kingfisher
import PictureBookLendingDomain
import SwiftUI

/// 絵本一覧のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct BookListView<RowAction: View>: View {
    let books: [Book]
    let searchText: Binding<String>
    let isEditMode: Bool
    let onSelect: (Book) -> Void
    let onEdit: (Book) -> Void
    let onDelete: (IndexSet) -> Void
    let rowAction: (Book) -> RowAction
    
    public init(
        books: [Book],
        searchText: Binding<String>,
        isEditMode: Bool = false,
        onSelect: @escaping (Book) -> Void,
        onEdit: @escaping (Book) -> Void,
        onDelete: @escaping (IndexSet) -> Void,
        @ViewBuilder rowAction: @escaping (Book) -> RowAction
    ) {
        self.books = books
        self.searchText = searchText
        self.isEditMode = isEditMode
        self.onSelect = onSelect
        self.onEdit = onEdit
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
                    if isEditMode {
                        Button {
                            onEdit(book)
                        } label: {
                            BookRowView(book: book, rowAction: rowAction)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(value: book) {
                            BookRowView(book: book, rowAction: rowAction)
                        }
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                onSelect(book)
                            })
                    }
                }
                .onDelete(perform: isEditMode ? onDelete : nil)
            }
            .searchable(
                text: searchText, placement: .navigationBarDrawer(displayMode: .always),
                prompt: "絵本のタイトルまたは著者で検索")
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
            KFImage(URL(string: book.smallThumbnail ?? book.thumbnail ?? ""))
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
            onSelect: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        ) { book in
            LoanButtonView(onTap: {})
        }
        .navigationTitle("絵本一覧")
    }
}
