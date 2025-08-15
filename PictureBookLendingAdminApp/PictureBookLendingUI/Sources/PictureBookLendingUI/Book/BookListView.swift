import Kingfisher
import PictureBookLendingDomain
import SwiftUI

/// 絵本セクション情報
/// 五十音順グループごとの絵本分類を表現
public struct BookSection: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let books: [Book]
    
    public init(id: String, title: String, books: [Book]) {
        self.id = id
        self.title = title
        self.books = books
    }
}

/// 絵本一覧のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
/// 画面制御はContainer Viewに委譲します。
/// セクション表示と通常のリスト表示の両方に対応
public struct BookListView<RowAction: View>: View {
    let books: [Book]
    let sections: [BookSection]
    let searchText: Binding<String>
    let isEditMode: Bool
    let useSections: Bool
    let onSelect: (Book) -> Void
    let onEdit: (Book) -> Void
    let onDelete: (IndexSet) -> Void
    let rowAction: (Book) -> RowAction
    
    /// 通常のリスト表示用イニシャライザ
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
        self.sections = []
        self.searchText = searchText
        self.isEditMode = isEditMode
        self.useSections = false
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.rowAction = rowAction
    }
    
    /// セクション表示用イニシャライザ
    public init(
        sections: [BookSection],
        searchText: Binding<String>,
        isEditMode: Bool = false,
        onSelect: @escaping (Book) -> Void,
        onEdit: @escaping (Book) -> Void,
        onDelete: @escaping (IndexSet) -> Void,
        @ViewBuilder rowAction: @escaping (Book) -> RowAction
    ) {
        self.books = []
        self.sections = sections
        self.searchText = searchText
        self.isEditMode = isEditMode
        self.useSections = true
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.rowAction = rowAction
    }
    
    public var body: some View {
        let isEmpty = useSections ? sections.allSatisfy { $0.books.isEmpty } : books.isEmpty
        
        if isEmpty {
            ContentUnavailableView(
                "絵本が登録されていません",
                systemImage: "book.closed",
                description: Text("設定画面から絵本を登録してください")
            )
        } else {
            List {
                if useSections {
                    ForEach(sections) { section in
                        Section(header: Text(section.title)) {
                            ForEach(section.books) { book in
                                bookRowContent(for: book)
                            }
                            .onDelete { indexSet in
                                if isEditMode {
                                    // セクション内の削除処理は上位のContainerViewで処理
                                    onDelete(indexSet)
                                }
                            }
                        }
                    }
                } else {
                    ForEach(books) { book in
                        bookRowContent(for: book)
                    }
                    .onDelete(perform: isEditMode ? onDelete : nil)
                }
            }
            #if os(iOS)
                .searchable(
                    text: searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "絵本のタイトルまたは著者で検索")
            #else
                .searchable(
                    text: searchText,
                    prompt: "絵本のタイトルまたは著者で検索")
            #endif
        }
    }
    
    /// 絵本行のコンテンツ
    @ViewBuilder
    private func bookRowContent(for book: Book) -> some View {
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
