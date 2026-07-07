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

/// 五十音チップの動作モード
///
/// - 貸出タブ＝インデックス：探している本がどこにあるか分からない画面では、
///   絞り込みで行が消えると「一覧に無い」と勘違いするためスクロールジャンプにする
/// - 図書管理＝フィルタ：対象のかな行だけ見たい管理の文脈では、
///   選んだかなグループだけに絞り込む（再タップで解除・従来動作）
///
/// BookListViewはジェネリック構造体のため、ネストさせずトップレベルに定義する
/// （ネストすると呼び出し側で `BookListView<RowAction>.KanaChipBehavior` になってしまうため）
public enum KanaChipBehavior {
    /// タップでその五十音セクションへスクロールする（行は消えない）
    case scrollIndex(scrollToTopTrigger: Int)
    /// タップでその五十音グループだけに絞り込む（再タップで解除）
    case filter(selection: Binding<KanaGroup?>)
}

/// BookListViewのレイアウト定数
///
/// BookListViewはジェネリック構造体のため、static storedプロパティを
/// ネストして持てない（"static stored properties not supported in generic types"）。
/// そのためファイルスコープに切り出す
private enum Layout {
    /// 五十音ジャンプ時の着地アンカー。上端(y:0)より少し下げて、
    /// 先頭行の上にあるセクション見出しが視界に入るようにする
    static let sectionJumpAnchor = UnitPoint(x: 0.5, y: 0.06)
}

/// 絵本一覧のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
/// 画面制御はContainer Viewに委譲します。
/// 五十音チップ（スクロールインデックス／フィルタ）とセクション表示に対応
public struct BookListView<RowAction: View>: View {
    /// 空状態アイコンのサイズ（Dynamic Typeに追従してスケール）
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 48
    
    /// 五十音グループでセクション化された絵本
    public let sections: [BookSection]
    /// 検索テキスト
    @Binding public var searchText: String
    /// 五十音チップの動作モード（スクロールインデックス／フィルタ）
    public let kanaChipBehavior: KanaChipBehavior
    /// 五十音フィルタの選択肢（フィルタモード専用）
    public let kanaFilterOptions: [KanaGroup]
    /// 選択中のソート方法
    @Binding public var selectedSortType: BookSortType
    /// 編集モードかどうか
    public let isEditMode: Bool
    /// 絵本編集時の動作
    public let onEdit: (Book) -> Void
    /// 絵本削除時の動作
    public let onDelete: (Book) -> Void
    /// 行タップ時の動作。指定すると行はNavigationLinkではなくボタンとして振る舞う
    /// （プッシュ遷移ではなくsheet等をホスト側で開く文脈用。nilなら従来どおりプッシュ遷移）
    public let onSelect: ((Book) -> Void)?
    /// 絵本のサムネイル画像URLを解決するクロージャ（App層で解決済みのURLを返す）
    public let imageURLProvider: (Book) -> String?
    /// 各行に表示するアクションビューを生成するクロージャ
    public let rowAction: (Book) -> RowAction
    
    /// BookListView イニシャライザ
    public init(
        sections: [BookSection],
        searchText: Binding<String>,
        kanaChipBehavior: KanaChipBehavior,
        kanaFilterOptions: [KanaGroup] = KanaGroup.allCases,
        selectedSortType: Binding<BookSortType>,
        isEditMode: Bool = false,
        onEdit: @escaping (Book) -> Void,
        onDelete: @escaping (Book) -> Void,
        onSelect: ((Book) -> Void)? = nil,
        imageURLProvider: @escaping (Book) -> String?,
        @ViewBuilder rowAction: @escaping (Book) -> RowAction
    ) {
        self.sections = sections
        self._searchText = searchText
        self.kanaChipBehavior = kanaChipBehavior
        self.kanaFilterOptions = kanaFilterOptions
        self._selectedSortType = selectedSortType
        self.isEditMode = isEditMode
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onSelect = onSelect
        self.imageURLProvider = imageURLProvider
        self.rowAction = rowAction
    }
    
    /// スクロールインデックスモードのトリガ値（`.onChange`用。フィルタモードでは実質未使用）
    private var scrollToTopTrigger: Int {
        if case .scrollIndex(let trigger) = kanaChipBehavior {
            trigger
        } else {
            0
        }
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 5) {
                kanaFilterSection(proxy: proxy)
                
                if sections.allSatisfy({ $0.books.isEmpty }) {
                    emptyStateView
                } else {
                    bookListSection
                }
            }
            .onChange(of: scrollToTopTrigger) { _, _ in
                // 貸出完了後の「次の貸出への引き継ぎ」：一覧を先頭へ戻す
                guard let firstBookId = sections.first?.books.first?.id else { return }
                withAnimation {
                    proxy.scrollTo(firstBookId, anchor: Layout.sectionJumpAnchor)
                }
            }
        }
    }
    
    // MARK: - Private Views
    
    /// 五十音チップ（動作は `kanaChipBehavior` に従う）＋ソート選択メニュー
    ///
    /// スクロールインデックスモードのチップは図書があるセクションだけ表示する
    /// （押しても何も起きないチップを作らない）。
    private func kanaFilterSection(proxy: ScrollViewProxy) -> some View {
        HStack {
            ScrollView(.horizontal) {
                HStack {
                    switch kanaChipBehavior {
                    case .scrollIndex:
                        ForEach(sections) { section in
                            Button(section.title) {
                                handleChipTap(section: section, proxy: proxy)
                            }
                            .buttonStyle(.bordered)
                            .tint(.secondary)
                        }
                    case .filter(let selection):
                        ForEach(kanaFilterOptions, id: \.self) { kanaGroup in
                            Button(kanaGroup.displayName) {
                                handleChipTap(kanaGroup: kanaGroup, selection: selection)
                            }
                            .buttonStyle(.bordered)
                            .tint(selection.wrappedValue == kanaGroup ? .accentColor : .secondary)
                        }
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
    
    /// 五十音チップのタップ処理（スクロールインデックスモード＝セクションへジャンプ）
    private func handleChipTap(section: BookSection, proxy: ScrollViewProxy) {
        // Listの遅延描画では見出しのIDがscrollToに解決されないため、
        // 確実に登録される先頭行のIDへスクロールする。
        // アンカーを上端より少し下げ、行の上にあるセクション見出しまで見せる
        guard let targetBookId = section.books.first?.id else { return }
        withAnimation {
            proxy.scrollTo(targetBookId, anchor: Layout.sectionJumpAnchor)
        }
    }
    
    /// 五十音チップのタップ処理（フィルタモード＝絞り込みトグル）
    private func handleChipTap(kanaGroup: KanaGroup, selection: Binding<KanaGroup?>) {
        // 未選択の場合は選択、選択中の場合は解除
        selection.wrappedValue = selection.wrappedValue == kanaGroup ? nil : kanaGroup
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: emptyIconSize))
                .foregroundStyle(.secondary)
            
            Text("図書が登録されていません")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text("設定画面から図書を登録してください")
                .font(.subheadline)
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
    }
    
    /// 絵本行のコンテンツ
    @ViewBuilder
    private func bookRowContent(for book: Book) -> some View {
        if isEditMode {
            Button {
                onEdit(book)
            } label: {
                BookRowView(book: book, imageURL: imageURLProvider(book), rowAction: rowAction)
                    // plainスタイルのボタンは不透明な描画部分しか当たり判定にならないため、
                    // サムネイルと文字のすき間や余白も含めて行全体をタップ可能にする
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else if let onSelect {
            Button {
                onSelect(book)
            } label: {
                BookRowView(book: book, imageURL: imageURLProvider(book), rowAction: rowAction)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: book) {
                BookRowView(book: book, imageURL: imageURLProvider(book), rowAction: rowAction)
            }
        }
    }
}

/// 絵本リスト行ビュー
///
/// 一覧の各行に表示する絵本情報のレイアウトを定義します。
public struct BookRowView<RowAction: View>: View {
    let book: Book
    let imageURL: String?
    let rowAction: (Book) -> RowAction
    
    public var body: some View {
        HStack {
            // サムネイル画像
            BookImageView(imageURL: imageURL) {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
                    .font(.title2)
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 65)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.title3)
                
                Text(book.author ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let managementNumber = book.managementNumber {
                    ManagementNumberBadge(text: managementNumber)
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
            kanaChipBehavior: .filter(selection: $selectedKanaFilter),
            selectedSortType: $selectedSortType,
            isEditMode: true,
            onEdit: { _ in },
            onDelete: { _ in },
            imageURLProvider: { book in
                book.displaySmallImageSource
            }
        ) { book in
            RowActionButton(onTap: {})
        }
        .navigationTitle("図書一覧")
    }
}

#Preview("スクロールインデックス（貸出タブ）") {
    @Previewable @State var searchText = ""
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
            kanaChipBehavior: .scrollIndex(scrollToTopTrigger: 0),
            selectedSortType: $selectedSortType,
            onEdit: { _ in },
            onDelete: { _ in },
            imageURLProvider: { book in
                book.displaySmallImageSource
            }
        ) { book in
            RowActionButton(onTap: {})
        }
        .navigationTitle("貸出")
    }
}
