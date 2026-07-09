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

/// 絵本一覧の表示形式
public enum BookDisplayMode: String, CaseIterable, Identifiable {
    case list = "list"
    case grid = "grid"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .list:
            return "リスト表示"
        case .grid:
            return "グリッド表示"
        }
    }
    
    public var iconName: String {
        switch self {
        case .list:
            return "list.bullet"
        case .grid:
            return "square.grid.2x2"
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

/// BookListViewのレイアウト定数
///
/// BookListViewはジェネリック構造体のため、static storedプロパティを
/// ネストして持てない（"static stored properties not supported in generic types"）。
/// そのためファイルスコープに切り出す
private enum Layout {
    /// 先頭へ戻すときの着地アンカー。上端(y:0)より少し下げて、
    /// 先頭行の上にあるセクション見出しが視界に入るようにする
    static let listTopAnchor = UnitPoint(x: 0.5, y: 0.06)
}

/// 絵本一覧のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
/// 画面制御はContainer Viewに委譲します。
/// 五十音チップによる絞り込みとセクション表示に対応し、
/// `scrollToTopTrigger`のインクリメントで一覧を先頭へ戻せます。
public struct BookListView<RowAction: View>: View {
    #if os(iOS)
        /// 水平サイズクラス（かなチップの表示可否の判定に使用）
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    /// 空状態アイコンのサイズ（Dynamic Typeに追従してスケール）
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 48
    
    /// 五十音グループでセクション化された絵本
    public let sections: [BookSection]
    /// 検索テキスト
    @Binding public var searchText: String
    /// 選択中の五十音フィルタ（そのかなグループだけに絞り込む・再タップで解除）
    @Binding public var selectedKanaFilter: KanaGroup?
    /// 五十音フィルタの選択肢
    public let kanaFilterOptions: [KanaGroup]
    /// 一覧を先頭へ戻すトリガ。値がインクリメントされると先頭行までスクロールする。
    /// 五十音チップの挙動とは独立しており、貸出完了後のリセット等から使う
    public let scrollToTopTrigger: Int
    /// 選択中のソート方法
    @Binding public var selectedSortType: BookSortType
    /// 一覧の表示形式（リスト／グリッド）
    @Binding public var displayMode: BookDisplayMode
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
        selectedKanaFilter: Binding<KanaGroup?>,
        kanaFilterOptions: [KanaGroup] = KanaGroup.allCases,
        scrollToTopTrigger: Int = 0,
        selectedSortType: Binding<BookSortType>,
        displayMode: Binding<BookDisplayMode>,
        isEditMode: Bool = false,
        onEdit: @escaping (Book) -> Void,
        onDelete: @escaping (Book) -> Void,
        onSelect: ((Book) -> Void)? = nil,
        imageURLProvider: @escaping (Book) -> String?,
        @ViewBuilder rowAction: @escaping (Book) -> RowAction
    ) {
        self.sections = sections
        self._searchText = searchText
        self._selectedKanaFilter = selectedKanaFilter
        self.kanaFilterOptions = kanaFilterOptions
        self.scrollToTopTrigger = scrollToTopTrigger
        self._selectedSortType = selectedSortType
        self._displayMode = displayMode
        self.isEditMode = isEditMode
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onSelect = onSelect
        self.imageURLProvider = imageURLProvider
        self.rowAction = rowAction
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 5) {
                kanaFilterSection
                
                if sections.allSatisfy({ $0.books.isEmpty }) {
                    emptyStateView
                } else {
                    switch displayMode {
                    case .list:
                        bookListSection
                    case .grid:
                        bookGridSection
                    }
                }
            }
            .onChange(of: scrollToTopTrigger) { _, _ in
                // 貸出完了後の「次の貸出への引き継ぎ」：一覧を先頭へ戻す
                guard let firstBookId = sections.first?.books.first?.id else { return }
                withAnimation {
                    proxy.scrollTo(firstBookId, anchor: Layout.listTopAnchor)
                }
            }
        }
    }
    
    // MARK: - Private Views
    
    /// かなチップを表示できる幅があるか
    ///
    /// 幅が確保できない環境（iPhoneやiPadの狭いSplit View＝compact）では
    /// チップを出さず、検索を主動線とする。macOSは常に表示する
    private var isKanaChipsVisible: Bool {
        #if os(iOS)
            horizontalSizeClass == .regular
        #else
            true
        #endif
    }
    
    /// 五十音チップ（タップでそのかなグループに絞り込み・再タップで解除）＋ソート選択メニュー
    private var kanaFilterSection: some View {
        HStack {
            if isKanaChipsVisible {
                // iOS 27ベータにHStack内の横ScrollViewが幅0のまま描画されない不具合があるため、
                // ScrollViewを使わず素のHStackで並べる（チップは全iPadのregular幅に収まる）。
                // 収まらない幅（狭いSplit View等）ではcompact時と同じ思想でチップを出さない
                ViewThatFits(in: .horizontal) {
                    kanaChips
                        .padding(.leading)
                    Color.clear
                        .frame(width: 0, height: 0)
                }
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
            
            // 表示形式切替（リスト／グリッド）。アイコンのみでコンパクト幅でも窮屈にならないようにする
            Menu {
                ForEach(BookDisplayMode.allCases) { mode in
                    Button {
                        displayMode = mode
                    } label: {
                        HStack {
                            Image(systemName: mode.iconName)
                            Text(mode.displayName)
                            if displayMode == mode {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: displayMode.iconName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .padding(.trailing)
        }
    }
    
    /// 五十音チップの並び
    private var kanaChips: some View {
        HStack {
            ForEach(kanaFilterOptions, id: \.self) { kanaGroup in
                Button(kanaGroup.displayName) {
                    handleChipTap(kanaGroup: kanaGroup)
                }
                .buttonStyle(.bordered)
                .tint(selectedKanaFilter == kanaGroup ? .accentColor : .secondary)
            }
        }
    }
    
    /// 五十音チップのタップ処理（絞り込みトグル）
    ///
    /// 未選択なら選択、選択中なら解除する。検索との排他（選択時に検索欄をクリアする等）は
    /// バインディング経由でContainer側のStateが担う
    private func handleChipTap(kanaGroup: KanaGroup) {
        selectedKanaFilter = selectedKanaFilter == kanaGroup ? nil : kanaGroup
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
    
    /// グリッドの列定義。iPadの広い幅では自動的に列数が増える（適応的グリッド）
    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 140), spacing: 16)]
    }
    
    private var bookGridSection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(section.books) { book in
                                bookGridCellContent(for: book)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    /// 絵本グリッドセルのコンテンツ
    ///
    /// タップ領域（表紙＋タイトル）とrowAction（貸出ボタン等）を縦に分離し、
    /// ボタン同士のタップ領域が重ならないようにする
    @ViewBuilder
    private func bookGridCellContent(for book: Book) -> some View {
        VStack(spacing: 8) {
            Group {
                if isEditMode {
                    Button {
                        onEdit(book)
                    } label: {
                        BookGridCoverView(book: book, imageURL: imageURLProvider(book))
                    }
                    .buttonStyle(.plain)
                } else if let onSelect {
                    Button {
                        onSelect(book)
                    } label: {
                        BookGridCoverView(book: book, imageURL: imageURLProvider(book))
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink(value: book) {
                        BookGridCoverView(book: book, imageURL: imageURLProvider(book))
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if isEditMode {
                    Button(role: .destructive) {
                        onDelete(book)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                            .font(.title3)
                    }
                    .padding(6)
                }
            }
            .contextMenu {
                if isEditMode {
                    Button("編集") { onEdit(book) }
                    Button("削除", role: .destructive) { onDelete(book) }
                }
            }
            
            rowAction(book)
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

/// 絵本グリッドセルの表紙＋タイトル表示（タップ可能領域）
///
/// rowAction（貸出ボタン等）は含まない。タップ領域とアクションボタンの
/// ジェスチャ競合を避けるため、呼び出し側で別要素として縦に並べる
private struct BookGridCoverView: View {
    /// タイトル表示領域の高さ（2行分固定・Dynamic Typeに追従してスケール）。
    /// lineLimitは最大行数の制限に過ぎず高さは固定しないため、1行タイトルのセルだけ
    /// 高さが縮んでrowActionの縦位置がずれてしまう問題をこれで防ぐ
    @ScaledMetric(relativeTo: .subheadline) private var titleHeight: CGFloat = 38
    
    let book: Book
    let imageURL: String?
    
    var body: some View {
        VStack(spacing: 6) {
            // 表紙画像は縦長・横長どちらでも正方形の枠に揃える（GeometryReaderで
            // 実際の表示幅を取り、その幅を一辺とした正方形枠の中に.fitで収める。
            // 画像は切り取らず、枠との差分は背景マテリアルの余白として見せる。
            // 枠を固定しないと画像の実際の比率によってセルの高さがバラつき、
            // 同じ行の他のセルとタイトル・rowActionの縦位置がズレてしまうため）
            GeometryReader { geometry in
                BookImageView(imageURL: imageURL) {
                    Image(systemName: "book.closed")
                        .foregroundStyle(.secondary)
                        .font(.largeTitle)
                }
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.width)
            }
            .aspectRatio(1, contentMode: .fit)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(book.title)
                .font(.subheadline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .frame(height: titleHeight, alignment: .top)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    @Previewable @State var searchText = ""
    @Previewable @State var selectedKanaFilter: KanaGroup?
    @Previewable @State var selectedSortType: BookSortType = .title
    @Previewable @State var displayMode: BookDisplayMode = .list
    
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
            displayMode: $displayMode,
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

#Preview("グリッド表示") {
    @Previewable @State var searchText = ""
    @Previewable @State var selectedKanaFilter: KanaGroup?
    @Previewable @State var selectedSortType: BookSortType = .title
    @Previewable @State var displayMode: BookDisplayMode = .grid
    
    let aBooks = [
        Book(title: "おおきなかぶ", author: "内田莉莎子", managementNumber: "あ001", kanaGroup: .a),
        Book(title: "あおくんときいろちゃん", author: "レオ・レオニ", managementNumber: "あ002", kanaGroup: .a),
        Book(title: "いないいないばあ", author: "松谷みよ子", managementNumber: "あ003", kanaGroup: .a),
    ]
    let kaBooks = [
        Book(title: "ぐりとぐら", author: "中川李枝子", managementNumber: "か001", kanaGroup: .ka),
        Book(title: "からすのパンやさん", author: "かこさとし", managementNumber: "か002", kanaGroup: .ka),
        Book(title: "きんぎょがにげた", author: "五味太郎", managementNumber: "か003", kanaGroup: .ka),
        Book(title: "ぐるんぱのようちえん", author: "西内ミナミ", managementNumber: "か004", kanaGroup: .ka),
    ]
    let saBooks = [
        Book(title: "しろくまちゃんのほっとけーき", author: "わかやまけん", managementNumber: "さ001", kanaGroup: .sa),
        Book(title: "３びきのやぎのがらがらどん", author: "せたていじ", managementNumber: "さ002", kanaGroup: .sa),
        Book(title: "そらまめくんのベッド", author: "なかやみわ", managementNumber: "さ003", kanaGroup: .sa),
    ]
    let taBooks = [
        Book(title: "だいくとおにろく", author: "松居直", managementNumber: "た001", kanaGroup: .ta),
        Book(title: "てぶくろ", author: "エウゲーニー・M・ラチョフ", managementNumber: "た002", kanaGroup: .ta),
    ]
    let haBooks = [
        Book(title: "はらぺこあおむし", author: "エリック・カール", managementNumber: "は001", kanaGroup: .ha),
        Book(title: "ぴっぽのたび", author: "駒形克己", managementNumber: "は002", kanaGroup: .ha),
        Book(title: "ぶたやまさんたら", author: "土田義晴", managementNumber: "は003", kanaGroup: .ha),
    ]
    let maBooks = [
        Book(title: "もこもこもこ", author: "谷川俊太郎", managementNumber: "ま001", kanaGroup: .ma),
        Book(title: "みんなうんち", author: "五味太郎", managementNumber: "ま002", kanaGroup: .ma),
    ]
    let yaBooks = [
        Book(title: "ゆかいなかえる", author: "松岡享子", managementNumber: "や001", kanaGroup: .ya)
    ]
    let raBooks = [
        Book(title: "ろくべえまってろよ", author: "灰谷健次郎", managementNumber: "ら001", kanaGroup: .ra),
        Book(title: "らいおんとねずみ", author: "いそっぷ", managementNumber: "ら002", kanaGroup: .ra),
    ]
    
    let sections = [
        BookSection(kanaGroup: .a, books: aBooks),
        BookSection(kanaGroup: .ka, books: kaBooks),
        BookSection(kanaGroup: .sa, books: saBooks),
        BookSection(kanaGroup: .ta, books: taBooks),
        BookSection(kanaGroup: .ha, books: haBooks),
        BookSection(kanaGroup: .ma, books: maBooks),
        BookSection(kanaGroup: .ya, books: yaBooks),
        BookSection(kanaGroup: .ra, books: raBooks),
    ]
    
    NavigationStack {
        BookListView(
            sections: sections,
            searchText: $searchText,
            selectedKanaFilter: $selectedKanaFilter,
            selectedSortType: $selectedSortType,
            displayMode: $displayMode,
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
