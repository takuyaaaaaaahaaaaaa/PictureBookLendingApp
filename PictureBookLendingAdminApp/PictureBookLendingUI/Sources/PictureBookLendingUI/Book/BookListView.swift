import Kingfisher
import PictureBookLendingDomain
import SwiftUI

/// 絵本のソート方法
public enum BookSortType: String, CaseIterable, Identifiable {
    case title = "title"
    case managementNumber = "managementNumber"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .title:
            return "あいうえお順"
        case .managementNumber:
            return "管理番号順"
        }
    }
    
    public var iconName: String {
        switch self {
        case .title:
            return "textformat.abc"
        case .managementNumber:
            return "number"
        }
    }
}

/// 絵本セクション情報
/// 五十音順グループごとの絵本分類を表現
public struct BookSection: Identifiable, Hashable {
    public let id: String
    public let kanaGroup: KanaGroup
    public let books: [Book]
    
    public init(kanaGroup: KanaGroup, books: [Book]) {
        self.id = kanaGroup.rawValue
        self.kanaGroup = kanaGroup
        self.books = books
    }
    
    /// 表示用のセクションタイトル
    public var title: String {
        kanaGroup.displayName
    }
}

/// 絵本一覧のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
/// 画面制御はContainer Viewに委譲します。
/// 五十音フィルターとセクション表示に対応
public struct BookListView<RowAction: View>: View {
    /// 五十音グループでセクション化された絵本
    public let sections: [BookSection]
    /// 検索テキスト
    @Binding public var searchText: String
    /// 選択中の五十音フィルタ
    @Binding public var selectedKanaFilter: KanaGroup?
    /// 五十音フィルタの選択肢
    public let kanaFilterOptions: [KanaGroup]
    /// 選択中のソート方法
    @Binding public var selectedSortType: BookSortType
    /// 編集モードかどうか
    public let isEditMode: Bool
    /// 絵本選択時の動作
    public let onSelect: (Book) -> Void
    /// 絵本編集時の動作
    public let onEdit: (Book) -> Void
    /// 絵本削除時の動作
    public let onDelete: (Book) -> Void
    /// 各行に表示するアクションビューを生成するクロージャ
    public let rowAction: (Book) -> RowAction
    
    /// BookListView イニシャライザ
    public init(
        sections: [BookSection],
        searchText: Binding<String>,
        selectedKanaFilter: Binding<KanaGroup?>,
        kanaFilterOptions: [KanaGroup] = KanaGroup.allCases,
        selectedSortType: Binding<BookSortType>,
        isEditMode: Bool = false,
        onSelect: @escaping (Book) -> Void,
        onEdit: @escaping (Book) -> Void,
        onDelete: @escaping (Book) -> Void,
        @ViewBuilder rowAction: @escaping (Book) -> RowAction
    ) {
        self.sections = sections
        self._searchText = searchText
        self._selectedKanaFilter = selectedKanaFilter
        self.kanaFilterOptions = kanaFilterOptions
        self._selectedSortType = selectedSortType
        self.isEditMode = isEditMode
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.rowAction = rowAction
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            kanaFilterSection
            
            if sections.allSatisfy({ $0.books.isEmpty }) {
                emptyStateView
            } else {
                bookListSection
            }
        }
    }
    
    // MARK: - Private Views
    
    /// 五十音フィルター
    private var kanaFilterSection: some View {
        HStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(kanaFilterOptions, id: \.self) { kanaGroup in
                        Button(kanaGroup.displayName) {
                            // 未選択の場合は選択、選択中の場合は解除
                            if selectedKanaFilter == kanaGroup {
                                selectedKanaFilter = nil
                            } else {
                                selectedKanaFilter = kanaGroup
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedKanaFilter == kanaGroup ? .accentColor : .secondary)
                    }
                }
                .padding(.leading)
            }
            
            Spacer()
            
            // ソート選択メニュー
            Menu {
                ForEach(BookSortType.allCases) { sortType in
                    Button {
                        selectedSortType = sortType
                    } label: {
                        HStack {
                            Image(systemName: sortType.iconName)
                            Text(sortType.displayName)
                            if selectedSortType == sortType {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: selectedSortType.iconName)
                    Text(selectedSortType.displayName)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.trailing)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("絵本が登録されていません")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("設定画面から絵本を登録してください")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var bookListSection: some View {
        List {
            ForEach(sections) { section in
                Section(header: Text(section.title)) {
                    ForEach(section.books) { book in
                        bookRowContent(for: book)
                    }
                    .onDelete(
                        perform: isEditMode
                            ? { indexSet in
                                // セクション内の削除処理
                                for index in indexSet {
                                    let book = section.books[index]
                                    onDelete(book)
                                }
                            } : nil)
                }
            }
        }
        #if os(iOS)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "絵本のタイトルまたは著者で検索")
        #else
            .searchable(
                text: $searchText,
                prompt: "絵本のタイトルまたは著者で検索")
        #endif
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
                
                Text(book.author ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let managementNumber = book.managementNumber {
                    Text("管理番号: \(managementNumber)")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(.capsule)
                }
            }
            
            Spacer()
            
            rowAction(book)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    @Previewable @State var searchText = ""
    @Previewable @State var selectedKanaFilter: KanaGroup?
    @Previewable @State var selectedSortType: BookSortType = .title
    
    let book1 = Book(
        title: "はらぺこあおむし", author: "エリック・カール", managementNumber: "は001", kanaGroup: .ha)
    let book2 = Book(title: "ぐりとぐら", author: "中川李枝子", managementNumber: "く002", kanaGroup: .ka)
    
    let sections = [
        BookSection(kanaGroup: .ka, books: [book2]),
        BookSection(kanaGroup: .ha, books: [book1]),
    ]
    
    NavigationStack {
        BookListView(
            sections: sections,
            searchText: $searchText,
            selectedKanaFilter: $selectedKanaFilter,
            selectedSortType: $selectedSortType,
            isEditMode: true,
            onSelect: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        ) { book in
            LoanButtonView(onTap: {})
        }
        .navigationTitle("絵本一覧")
    }
}
