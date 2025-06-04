import Foundation

/// 絵本モデル
/// 貸し出しシステムで管理される絵本の情報を表します
public struct Book: Identifiable, Codable {
    /// 絵本の一意識別子
    public var id: UUID
    /// 絵本のタイトル
    public var title: String
    /// 絵本の著者名
    public var author: String
    
    /// 絵本モデルの初期化
    /// - Parameters:
    ///   - id: 絵本の一意識別子（デフォルトでは新しいUUIDが生成されます）
    ///   - title: 絵本のタイトル
    ///   - author: 絵本の著者名
    public init(id: UUID = UUID(), title: String, author: String) {
        self.id = id
        self.title = title
        self.author = author
    }
}