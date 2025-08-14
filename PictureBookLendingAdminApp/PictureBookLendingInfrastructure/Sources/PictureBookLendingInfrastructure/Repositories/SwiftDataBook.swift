import Foundation
import SwiftData

/// SwiftData用の絵本モデル
///
/// SwiftDataで永続化するための絵本モデル。
/// ドメインモデルのBookと1対1で対応し、SwiftDataの制約に合わせた構造になっています。
///
/// - Note: `description`は予約語のため`bookDescription`として定義
/// - Note: `URL`型は直接保存できないため`thumbnailURLString`として文字列で保存
@Model
final public class SwiftDataBook {
    /// 絵本の一意識別子
    @Attribute(.unique) public var id: UUID
    
    /// 絵本のタイトル
    public var title: String
    
    /// 著者名
    public var author: String
    
    /// 独自の管理番号
    public var managementNumber: String?
    
    /// ISBN-13コード
    public var isbn13: String?
    
    /// 出版社名
    public var publisher: String?
    
    /// 出版日（YYYY-MM-DD形式の文字列）
    public var publishedDate: String?
    
    /// 絵本の説明・概要
    /// - Note: `description`は予約語のため`bookDescription`として定義
    public var bookDescription: String?
    
    /// 小さなサムネイル画像のURL
    public var smallThumbnail: String?
    
    /// 通常サイズのサムネイル画像のURL
    public var thumbnail: String?
    
    /// 対象年齢（rawValue文字列として保存）
    public var targetAge: String?
    
    /// ページ数
    public var pageCount: Int?
    
    /// カテゴリ・ジャンルの配列
    public var categories: [String]
    
    /// イニシャライザ
    ///
    /// - Parameters:
    ///   - id: 絵本の一意識別子
    ///   - title: 絵本のタイトル
    ///   - author: 著者名
    ///   - managementNumber: 独自の管理番号
    ///   - isbn13: ISBN-13コード
    ///   - publisher: 出版社名
    ///   - publishedDate: 出版日
    ///   - bookDescription: 絵本の説明・概要
    ///   - smallThumbnail: 小さなサムネイル画像のURL
    ///   - thumbnail: 通常サイズのサムネイル画像のURL
    ///   - targetAge: 対象年齢
    ///   - pageCount: ページ数
    ///   - categories: カテゴリ・ジャンルの配列
    public init(
        id: UUID,
        title: String,
        author: String,
        isbn13: String? = nil,
        publisher: String? = nil,
        publishedDate: String? = nil,
        bookDescription: String? = nil,
        smallThumbnail: String? = nil,
        thumbnail: String? = nil,
        targetAge: String? = nil,
        pageCount: Int? = nil,
        categories: [String] = [],
        managementNumber: String? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.managementNumber = managementNumber
        self.isbn13 = isbn13
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.bookDescription = bookDescription
        self.smallThumbnail = smallThumbnail
        self.thumbnail = thumbnail
        self.targetAge = targetAge
        self.pageCount = pageCount
        self.categories = categories
    }
}
