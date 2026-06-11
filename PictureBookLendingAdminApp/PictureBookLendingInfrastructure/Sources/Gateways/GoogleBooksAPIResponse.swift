import Foundation

// MARK: - Google Books API Response

/// Google Books API レスポンスルート
///
/// Google Books API v1のvolumes検索エンドポイントからのレスポンスを表現するモデル。
/// 複数の書籍情報（Volume）を含む可能性があります。
///
/// - Note: itemsがnilの場合は、検索結果が0件であることを示します
struct VolumesResponse: Decodable {
    /// 検索結果の書籍情報配列
    /// 検索結果が0件の場合はnilになります
    let items: [Volume]?
}

/// 書籍ボリューム
///
/// Google Books APIにおける個別の書籍情報を表現するモデル。
/// 書籍の詳細情報（VolumeInfo）を含みます。
struct Volume: Decodable {
    /// 書籍の詳細情報
    let volumeInfo: VolumeInfo
}

/// 書籍詳細情報
///
/// Google Books APIから取得される書籍の詳細情報を表現するモデル。
/// タイトル、著者、出版社、ISBN等の書籍メタデータが含まれます。
///
/// - Note: すべてのプロパティがoptionalであり、APIから取得できない場合があります
struct VolumeInfo: Decodable {
    /// 書籍タイトル
    let title: String?
    
    /// 著者名の配列
    let authors: [String]?
    
    /// 出版社名
    let publisher: String?
    
    /// 出版日（YYYY-MM-DD形式の文字列）
    let publishedDate: String?
    
    /// 書籍の説明・概要
    let description: String?
    
    /// ページ数
    let pageCount: Int?
    
    /// カテゴリ・ジャンルの配列
    let categories: [String]?
    
    /// 書籍の画像リンク情報
    let imageLinks: ImageLinks?
    
    /// ISBN等の業界識別子の配列
    let industryIdentifiers: [IndustryIdentifier]?
    
    /// Google Books上の書籍詳細ページURL
    let infoLink: URL?
}

/// 画像リンク
///
/// Google Books APIで提供される書籍の表紙画像URLを格納するモデル。
/// 異なるサイズの画像URLが提供されます。
struct ImageLinks: Decodable {
    /// 小さなサムネイル画像のURL
    let smallThumbnail: String?
    
    /// 通常サイズのサムネイル画像のURL
    let thumbnail: String?
}

/// 業界識別子（ISBN等）
///
/// 書籍を識別するための業界標準識別子を表現するモデル。
/// ISBN-10、ISBN-13等の異なる形式の識別子が含まれます。
struct IndustryIdentifier: Decodable {
    /// 識別子の種類（"ISBN_10"、"ISBN_13"等）
    let type: String
    
    /// 識別子の値
    let identifier: String
}
