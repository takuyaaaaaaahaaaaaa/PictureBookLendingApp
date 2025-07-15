import Foundation

/// 利用者モデル
/// 絵本を借りる利用者の情報を表します
public struct User: Identifiable, Codable, Hashable {
    /// 利用者の一意識別子
    public var id: UUID
    /// 利用者の名前
    public var name: String
    /// 所属する組
    public var group: String
    /// 所属するクラス（組）のID
    public var classGroupId: UUID
    
    /// 利用者モデルの初期化
    /// - Parameters:
    ///   - id: 利用者の一意識別子（デフォルトでは新しいUUIDが生成されます）
    ///   - name: 利用者の名前
    ///   - group: 所属する組
    ///   - classGroupId: 所属するクラス（組）のID
    public init(id: UUID = UUID(), name: String, group: String, classGroupId: UUID) {
        self.id = id
        self.name = name
        self.group = group
        self.classGroupId = classGroupId
    }
}
