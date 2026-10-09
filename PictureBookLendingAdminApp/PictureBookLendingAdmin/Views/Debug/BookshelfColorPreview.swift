#if DEBUG
    import PictureBookLendingDomain
    import PictureBookLendingUI
    import SwiftUI
    
    /// 本体のAccentColorを使う見本。実データ・表紙画像・保存処理を持たない。
    struct BookshelfColorPreview: View {
        @State private var searchText = ""
        @State private var selectedSortType: BookSortType = .title
        @State private var displayMode: BookDisplayMode = .shelf
        @State private var displayScale: BookDisplayScale = .standard
        
        @State private var sampleSections: [BookSection]
        
        init(includesWrappedRow: Bool = false) {
            _sampleSections = State(
                initialValue: Self.makeSections(includesWrappedRow: includesWrappedRow))
        }
        
        private static func makeSections(includesWrappedRow: Bool) -> [BookSection] {
            let additionalBooks =
                includesWrappedRow
                ? (1...24).map { Book(title: "あ行の見本 \($0)", managementNumber: "見本\($0)") }
                : []
            return [
                BookSection(
                    kanaGroup: .a,
                    books: [
                        Book(title: "おおきなかぶ", managementNumber: "あ001"),
                        Book(title: "あおくんときいろちゃん", managementNumber: "あ002"),
                        Book(title: "いないいないばあ", managementNumber: "あ003"),
                    ] + additionalBooks),
                BookSection(
                    kanaGroup: .ka,
                    books: [
                        Book(title: "ぐりとぐら", managementNumber: "か001"),
                        Book(title: "からすのパンやさん", managementNumber: "か002"),
                        Book(title: "きんぎょがにげた", managementNumber: "か003"),
                        Book(title: "ぐるんぱのようちえん", managementNumber: "か004"),
                    ]),
            ]
        }
        
        private var sections: [BookSection] {
            sampleSections.compactMap { section -> BookSection? in
                let books = section.books.filter {
                    searchText.isEmpty || $0.title.localizedStandardContains(searchText)
                }.sorted {
                    selectedSortType == .title
                        ? $0.title < $1.title
                        : ($0.managementNumber ?? "") < ($1.managementNumber ?? "")
                }
                return books.isEmpty ? nil : BookSection(kanaGroup: section.kanaGroup, books: books)
            }
        }
        
        var body: some View {
            BookListView(
                sections: sections,
                searchText: $searchText,
                selectedKanaFilter: .constant(nil),
                showsControls: false,
                selectedSortType: $selectedSortType,
                displayMode: $displayMode,
                displayScale: displayScale,
                onEdit: { _ in }, onDelete: { _ in }, onSelect: { _ in },
                imageURLProvider: { _ in nil }
            ) { book in
                if book.managementNumber == "あ002" {
                    RowActionButton(
                        title: "貸出中", systemImage: "book.closed", tint: AppColor.chipSurface,
                        foreground: AppColor.libraryTitle, border: AppColor.returnCardBorder,
                        onTap: {}
                    )
                } else {
                    RowActionButton(
                        title: "借りる", tint: AppColor.borrowAction,
                        foreground: AppColor.borrowActionForeground, hasSubtleDepth: true,
                        onTap: {}
                    )
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                BookDisplayScaleToggleButton(scale: $displayScale).padding(24)
            }
            .navigationTitle("貸出")
            .toolbar {
                BookDisplayToolbar(sort: $selectedSortType, mode: $displayMode)
            }
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "図書のタイトルまたは著者で検索"
                )
            #else
                .searchable(text: $searchText, prompt: "図書のタイトルまたは著者で検索")
            #endif
        }
    }
    
    #Preview("本棚・横幅1194・ライト", traits: .fixedLayout(width: 1194, height: 834)) {
        NavigationStack { BookshelfColorPreview() }.preferredColorScheme(.light)
    }
    
    #Preview("本棚・横幅1194・ダーク", traits: .fixedLayout(width: 1194, height: 834)) {
        NavigationStack { BookshelfColorPreview() }.preferredColorScheme(.dark)
    }
    
    #Preview("本棚・狭幅・大きい文字", traits: .fixedLayout(width: 390, height: 844)) {
        NavigationStack { BookshelfColorPreview() }.dynamicTypeSize(.accessibility1)
    }
    
    #Preview("カラートークン・ライト／ダーク", traits: .fixedLayout(width: 760, height: 1100)) {
        ScrollView { ColorTokenCatalogView() }
    }
#endif
