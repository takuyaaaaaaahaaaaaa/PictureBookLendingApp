import Foundation

/// 貸出設定
///
/// 絵本の貸出に関する設定値を管理します。
public struct LoanSettings: Codable, Equatable, Sendable {
    /// デフォルト貸出期間（日数）
    public let defaultLoanPeriodDays: Int
    
    /// 一人当たりの最大貸出可能数
    public let maxBooksPerUser: Int
    
    /// イニシャライザ
    /// - Parameters:
    ///   - defaultLoanPeriodDays: デフォルト貸出期間（日数）
    ///   - maxBooksPerUser: 一人当たりの最大貸出可能数
    public init(defaultLoanPeriodDays: Int, maxBooksPerUser: Int = 1) {
        self.defaultLoanPeriodDays = defaultLoanPeriodDays
        self.maxBooksPerUser = maxBooksPerUser
    }
    
    /// デフォルト設定値
    public static let `default` = LoanSettings(defaultLoanPeriodDays: 14, maxBooksPerUser: 1)
    
    /// 設定が有効かどうかを検証
    /// - Returns: 有効な場合true、無効な場合false
    public func isValid() -> Bool {
        defaultLoanPeriodDays > 0 && defaultLoanPeriodDays <= 365 && maxBooksPerUser > 0
    }
    
    /// 貸出日から返却期限日を計算
    /// - Parameter loanDate: 貸出日
    /// - Returns: 返却期限日
    public func calculateDueDate(from loanDate: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: defaultLoanPeriodDays, to: loanDate)
            ?? loanDate
    }
}
