import Foundation

/// 利用者モデル
/// 絵本を借りる利用者（保護者・子供）の情報を表します
public struct User: Identifiable, Codable {
    /// 利用者の一意識別子
    public var id: UUID
    /// 利用者の名前
    public var name: String
    /// 所属するクラス/組
    public var group: String
    
    /// 利用者モデルの初期化
    /// - Parameters:
    ///   - id: 利用者の一意識別子（デフォルトでは新しいUUIDが生成されます）
    ///   - name: 利用者の名前
    ///   - group: 所属するクラス/組
    public init(id: UUID = UUID(), name: String, group: String) {
        self.id = id
        self.name = name
        self.group = group
    }
}