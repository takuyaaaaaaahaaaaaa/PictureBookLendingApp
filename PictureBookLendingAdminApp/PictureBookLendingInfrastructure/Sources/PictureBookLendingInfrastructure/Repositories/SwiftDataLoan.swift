import Foundation
import PictureBookLendingDomain
import SwiftData

/// SwiftData用の貸出モデル
///
/// SwiftDataで永続化するための貸出モデル。
/// ドメインモデルのLoanと1対1で対応し、絵本の貸出・返却状況を管理します。
@Model
final public class SwiftDataLoan {
    /// 貸出記録の一意識別子
    @Attribute(.unique) public var id: UUID
    
    /// 貸出された絵本のID
    public var bookId: UUID
    
    /// 借りた利用者の情報（貸出時点でのスナップショット）
    public var user: User
    
    /// 貸出日
    public var loanDate: Date
    
    /// 返却期限日
    public var dueDate: Date
    
    /// 実際の返却日（未返却の場合はnil）
    public var returnedDate: Date?
    
    /// イニシャライザ
    ///
    /// - Parameters:
    ///   - id: 貸出記録の一意識別子
    ///   - bookId: 貸出された絵本のID
    ///   - user: 借りた利用者の情報
    ///   - loanDate: 貸出日
    ///   - dueDate: 返却期限日
    ///   - returnedDate: 実際の返却日（未返却の場合はnil）
    public init(
        id: UUID,
        bookId: UUID,
        user: User,
        loanDate: Date,
        dueDate: Date,
        returnedDate: Date? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.user = user
        self.loanDate = loanDate
        self.dueDate = dueDate
        self.returnedDate = returnedDate
    }
}
