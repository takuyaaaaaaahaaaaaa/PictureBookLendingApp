import Foundation

/// 絵本モデル
/// 貸出システムで管理される絵本の情報を表します
public struct Book: Identifiable, Codable, Hashable {
    /// 絵本の一意識別子
    public var id: UUID
    /// 絵本のタイトル
    public var title: String
    /// 絵本の著者名
    public var author: String
    /// ISBN-13コード（13桁の数字文字列）
    public var isbn13: String?
    /// 出版社名
    public var publisher: String?
    /// 出版日（ISO 8601形式の文字列）
    public var publishedDate: String?
    /// 絵本の説明・あらすじ
    public var description: String?
    /// サムネイル画像のURL
    public var thumbnailURL: URL?
    /// 対象年齢
    public var targetAge: Int?
    /// ページ数
    public var pageCount: Int?
    /// カテゴリ・ジャンル
    public var categories: [String]
    
    /// 絵本モデルの初期化（完全版）
    /// - Parameters:
    ///   - id: 絵本の一意識別子（デフォルトでは新しいUUIDが生成されます）
    ///   - title: 絵本のタイトル
    ///   - author: 絵本の著者名
    ///   - isbn13: ISBN-13コード（任意）
    ///   - publisher: 出版社名（任意）
    ///   - publishedDate: 出版日（任意）
    ///   - description: 説明・あらすじ（任意）
    ///   - thumbnailURL: サムネイル画像のURL（任意）
    ///   - targetAge: 対象年齢（任意）
    ///   - pageCount: ページ数（任意）
    ///   - categories: カテゴリ・ジャンル（デフォルトは空配列）
    public init(
        id: UUID = UUID(),
        title: String,
        author: String,
        isbn13: String? = nil,
        publisher: String? = nil,
        publishedDate: String? = nil,
        description: String? = nil,
        thumbnailURL: URL? = nil,
        targetAge: Int? = nil,
        pageCount: Int? = nil,
        categories: [String] = []
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.isbn13 = isbn13
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.targetAge = targetAge
        self.pageCount = pageCount
        self.categories = categories
    }
    
    /// 絵本モデルの初期化（基本版・後方互換性のため）
    /// - Parameters:
    ///   - id: 絵本の一意識別子（デフォルトでは新しいUUIDが生成されます）
    ///   - title: 絵本のタイトル
    ///   - author: 絵本の著者名
    public init(id: UUID = UUID(), title: String, author: String) {
        self.id = id
        self.title = title
        self.author = author
        self.isbn13 = nil
        self.publisher = nil
        self.publishedDate = nil
        self.description = nil
        self.thumbnailURL = nil
        self.targetAge = nil
        self.pageCount = nil
        self.categories = []
    }
}
