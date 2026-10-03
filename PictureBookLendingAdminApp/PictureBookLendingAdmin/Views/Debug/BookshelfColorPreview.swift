#if DEBUG
    import PictureBookLendingDomain
    import PictureBookLendingUI
    import SwiftUI
    
    /// 本体のAccentColorを使う見本。実データ・表紙画像・保存処理を持たない。
    struct BookshelfColorPreview: View {
        @State private var searchText = ""
        @State private var selectedKanaFilter: KanaGroup?
        @State private var selectedSortType: BookSortType = .title
        @State private var displayMode: BookDisplayMode = .shelf
        @State private var displayScale: BookDisplayScale = .standard
        
        private let includesWrappedRow: Bool
        
        init(includesWrappedRow: Bool = false) {
            self.includesWrappedRow = includesWrappedRow
        }
        
        private var additionalBooks: [Book] {
            includesWrappedRow
                ? (1...6).map { Book(title: "あ行の見本 \($0)", managementNumber: "見本\($0)") }
                : []
        }
        
        private var sections: [BookSection] {
            [
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
        
        var body: some View {
            BookListView(
                sections: sections,
                searchText: $searchText,
                selectedKanaFilter: $selectedKanaFilter,
                selectedSortType: $selectedSortType,
                displayMode: $displayMode,
                displayScale: displayScale,
                onEdit: { _ in }, onDelete: { _ in }, onSelect: { _ in },
                imageURLProvider: { _ in nil }
            ) { book in
                if book.managementNumber == "あ002" {
                    RowActionButton(
                        title: "貸出中", systemImage: "book.closed", tint: AppColor.lentSurface,
                        foreground: AppColor.lentForeground, onTap: {}
                    )
                } else {
                    RowActionButton(title: "借りる", onTap: {})
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                BookDisplayScaleToggleButton(scale: $displayScale).padding(24)
            }
            .navigationTitle("貸出")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "図書のタイトルまたは著者で検索")
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
