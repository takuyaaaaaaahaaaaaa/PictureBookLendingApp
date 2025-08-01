import Foundation
import SwiftData

/// SwiftData用のクラス（組）モデル
///
/// SwiftDataで永続化するためのクラス（組）モデル。
/// ドメインモデルのClassGroupと1対1で対応し、保育園・幼稚園のクラス情報を管理します。
@Model
final public class SwiftDataClassGroup {
    /// クラスの一意識別子
    @Attribute(.unique) public var id: UUID
    
    /// クラス名（例: "さくら組", "年長A組"）
    public var name: String
    
    /// 年齢グループ（0歳児、1歳児など）
    public var ageGroup: Int
    
    /// 年度（西暦）
    public var year: Int
    
    /// イニシャライザ
    ///
    /// - Parameters:
    ///   - id: クラスの一意識別子
    ///   - name: クラス名
    ///   - ageGroup: 年齢グループ
    ///   - year: 年度（西暦）
    public init(id: UUID, name: String, ageGroup: Int, year: Int) {
        self.id = id
        self.name = name
        self.ageGroup = ageGroup
        self.year = year
    }
}
