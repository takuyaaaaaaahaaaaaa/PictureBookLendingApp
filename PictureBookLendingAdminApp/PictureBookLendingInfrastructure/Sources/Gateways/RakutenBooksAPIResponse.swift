import Foundation

/// 楽天ブックス書籍検索APIのレスポンス
///
/// Rakuten Books Book Search API (version:2017-04-04) のJSONレスポンスを
/// デコードするためのDTOです。
/// 参考: https://webservice.rakuten.co.jp/documentation/books-book-search
struct RakutenBooksResponse: Decodable {
    /// 検索結果の書籍リスト
    let items: [ItemContainer]?
    /// 検索結果の総件数
    let count: Int?
    
    enum CodingKeys: String, CodingKey {
        case items = "Items"
        case count
    }
    
    /// 各書籍が `Item` キーでラップされているための中間コンテナ
    struct ItemContainer: Decodable {
        let item: RakutenBookItem
        
        enum CodingKeys: String, CodingKey {
            case item = "Item"
        }
    }
}

/// 楽天ブックスAPIの書籍情報
struct RakutenBookItem: Decodable {
    /// 書籍タイトル
    let title: String?
    /// 著者名
    let author: String?
    /// 出版社名
    let publisherName: String?
    /// ISBNコード
    let isbn: String?
    /// 書籍の説明・あらすじ
    let itemCaption: String?
    /// 発売日（例: "1976年05月"。ISO形式ではない）
    let salesDate: String?
    /// 小サイズの書影URL
    let smallImageUrl: String?
    /// 中サイズの書影URL
    let mediumImageUrl: String?
    /// 大サイズの書影URL
    let largeImageUrl: String?
    /// 書籍サイズ（例: "絵本", "単行本"）
    let size: String?
    /// シリーズ名
    let seriesName: String?
}
