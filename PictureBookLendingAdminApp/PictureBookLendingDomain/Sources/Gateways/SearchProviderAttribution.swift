import Foundation

/// 書籍検索データ提供元のクレジット表記
///
/// 一部の外部API（例: 楽天ウェブサービス）は、利用規約により
/// データ提供元のクレジット表記をアプリ内に表示することを義務付けています。
/// このモデルは、そのクレジットを表示するために必要な文言とリンク先を表します。
public struct SearchProviderAttribution: Equatable, Sendable {
    /// 表示する文言
    public let text: String
    /// クレジットのリンク先URL（任意）
    public let url: URL?
    
    public init(text: String, url: URL?) {
        self.text = text
        self.url = url
    }
    
    /// 楽天ウェブサービスのクレジット表記
    ///
    /// 楽天ウェブサービスの規約で定められた文言とリンク先。
    /// 参考: https://webservice.rakuten.co.jp/guide/credit
    public static let rakuten = SearchProviderAttribution(
        text: "Supported by Rakuten Developers",
        url: URL(string: "https://developers.rakuten.com/")
    )
}
