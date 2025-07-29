import Foundation
import SwiftData

/// SwiftData用の利用者モデル
///
/// SwiftDataで永続化するための利用者モデル。
/// ドメインモデルのUserと1対1で対応し、園児や児童の情報を保存します。
@Model
final public class SwiftDataUser {
    /// 利用者の一意識別子
    public var id: UUID
    
    /// 利用者の名前
    public var name: String
    
    /// 所属するクラス（組）のID
    public var classGroupId: UUID
    
    /// イニシャライザ
    ///
    /// - Parameters:
    ///   - id: 利用者の一意識別子
    ///   - name: 利用者の名前
    ///   - classGroupId: 所属するクラス（組）のID
    public init(id: UUID, name: String, classGroupId: UUID) {
        self.id = id
        self.name = name
        self.classGroupId = classGroupId
    }
}
