import PictureBookLendingDomain

/// 絵本リストのセクション分類
/// 五十音順グループごとに絵本をセクション化するためのモデル
struct AdminBookSection: Identifiable, Hashable {
    let id: String
    let kanaGroup: KanaGroup
    let books: [Book]
    
    init(kanaGroup: KanaGroup, books: [Book]) {
        self.id = kanaGroup.rawValue
        self.kanaGroup = kanaGroup
        self.books = books
    }
    
    /// 表示用のセクションタイトル
    var displayTitle: String {
        kanaGroup.displayName
    }
    
    /// セクションが空かどうか
    var isEmpty: Bool {
        books.isEmpty
    }
}

extension AdminBookSection {
    /// 絵本リストから五十音順セクションを作成
    /// - Parameter books: 分類対象の絵本リスト
    /// - Returns: 五十音順にソートされたセクションリスト
    static func createSections(from books: [Book]) -> [AdminBookSection] {
        // 五十音グループごとに絵本を分類
        let groupedBooks = Dictionary(grouping: books) { book -> KanaGroup in
            return book.kanaGroup ?? .other
        }
        
        // セクションを作成し、五十音順にソート
        let sections = groupedBooks.compactMap { (kanaGroup, books) in
            AdminBookSection(kanaGroup: kanaGroup, books: books.sorted { $0.title < $1.title })
        }
        
        // 五十音順にソート（空のセクションは除外）
        return
            sections
            .filter { !$0.isEmpty }
            .sorted { $0.kanaGroup.sortOrder < $1.kanaGroup.sortOrder }
    }
}
