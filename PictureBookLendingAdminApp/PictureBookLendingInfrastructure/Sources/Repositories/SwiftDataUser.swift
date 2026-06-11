import Foundation
import PictureBookLendingDomain
import SwiftData

/// SwiftData用の利用者モデル（スキーマV2）
///
/// SwiftDataで永続化するための利用者モデル。
/// ドメインモデルのUserと1対1で対応し、園児や児童の情報を保存します。
@Model
final public class SwiftDataUser {
    /// 利用者の一意識別子
    @Attribute(.unique) public var id: UUID
    
    /// 利用者の名前
    public var name: String
    
    /// 所属するクラス（組）のID
    public var classGroupId: UUID
    
    /// 利用者種別（本人・保護者）
    public var userTypeRawValue: String = "child"
    
    /// 関連する本人のID（保護者の場合のみ設定）
    public var relatedChildId: UUID?
    
    /// イニシャライザ
    ///
    /// - Parameters:
    ///   - id: 利用者の一意識別子
    ///   - name: 利用者の名前
    ///   - classGroupId: 所属するクラス（組）のID
    ///   - userType: 利用者種別
    public init(
        id: UUID,
        name: String,
        classGroupId: UUID,
        userType: UserType
    ) {
        self.id = id
        self.name = name
        self.classGroupId = classGroupId
        
        switch userType {
        case .child:
            self.userTypeRawValue = "child"
            self.relatedChildId = nil
        case .guardian(let relatedChildId):
            self.userTypeRawValue = "guardian"
            self.relatedChildId = relatedChildId
        }
    }
}
