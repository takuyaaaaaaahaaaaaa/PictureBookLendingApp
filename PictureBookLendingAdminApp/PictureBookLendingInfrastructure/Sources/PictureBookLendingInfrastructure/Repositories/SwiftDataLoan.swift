import Foundation
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
    
    /// 借りた利用者のID
    public var userId: UUID
    
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
    ///   - userId: 借りた利用者のID
    ///   - loanDate: 貸出日
    ///   - dueDate: 返却期限日
    ///   - returnedDate: 実際の返却日（未返却の場合はnil）
    public init(
        id: UUID,
        bookId: UUID,
        userId: UUID,
        loanDate: Date,
        dueDate: Date,
        returnedDate: Date? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.userId = userId
        self.loanDate = loanDate
        self.dueDate = dueDate
        self.returnedDate = returnedDate
    }
}
