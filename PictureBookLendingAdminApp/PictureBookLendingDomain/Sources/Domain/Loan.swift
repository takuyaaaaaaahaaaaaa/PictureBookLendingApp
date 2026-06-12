import Foundation

/// 貸出モデル
/// 絵本の貸出情報を管理します
public struct Loan: Identifiable, Codable {
    /// 貸出の一意識別子
    public var id: UUID
    /// 貸し出された絵本のID
    public var bookId: UUID
    /// 借りた利用者の情報（貸出時点でのスナップショット）
    public var user: User
    /// 貸出日
    public var loanDate: Date
    /// 返却期限日
    public var dueDate: Date
    /// 返却日（未返却の場合はnil）
    public var returnedDate: Date?
    
    /// 返却済みかどうかを示す計算プロパティ
    public var isReturned: Bool {
        returnedDate != nil
    }
    
    /// 貸出モデルの初期化
    /// - Parameters:
    ///   - id: 貸出の一意識別子（デフォルトでは新しいUUIDが生成されます）
    ///   - bookId: 貸し出された絵本のID
    ///   - user: 借りた利用者の情報
    ///   - loanDate: 貸出日
    ///   - dueDate: 返却期限日
    ///   - returnedDate: 返却日（デフォルトはnil）
    public init(
        id: UUID = UUID(), bookId: UUID, user: User, loanDate: Date, dueDate: Date,
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
