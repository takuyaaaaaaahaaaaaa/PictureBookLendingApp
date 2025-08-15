import Foundation

/// 利用者の種別
public enum UserType: Codable, Hashable {
    /// 本人
    case child
    /// 保護者（関連する本人のID）
    case guardian(relatedChildId: UUID)
    
    /// 表示用の日本語名
    public var displayName: String {
        switch self {
        case .child:
            return "本人"
        case .guardian:
            return "保護者"
        }
    }
}

/// 利用者モデル
/// 絵本を借りる利用者の情報を表します
public struct User: Identifiable, Codable, Hashable {
    /// 利用者の一意識別子
    public var id: UUID
    /// 利用者の名前
    public var name: String
    /// 所属する組のID
    public var classGroupId: UUID
    /// 利用者種別（本人・保護者）
    public var userType: UserType
    
    /// 利用者モデルの初期化
    /// - Parameters:
    ///   - id: 利用者の一意識別子（デフォルトでは新しいUUIDが生成されます）
    ///   - name: 利用者の名前
    ///   - classGroupId: 所属する組のID
    ///   - userType: 利用者種別（デフォルトは本人）
    public init(
        id: UUID = UUID(),
        name: String,
        classGroupId: UUID,
        userType: UserType = .child
    ) {
        self.id = id
        self.name = name
        self.classGroupId = classGroupId
        self.userType = userType
    }
}
