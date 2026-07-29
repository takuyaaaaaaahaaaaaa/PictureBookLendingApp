import Foundation

/// 貸出の節目判定サービス
///
/// 新しい貸出が「お祝いに値する節目」に達したかを、同じ利用者の過去の貸出記録から判定します。
/// 判定は純粋な計算のみで、永続化や表示には関与しません。
public struct LoanMilestoneEvaluator: Sendable {
    
    /// 節目と判定する回数（階段式）
    ///
    /// 毎週借りる園児だと等間隔（4週ごと等）ではお祝いが月1回以上発火して
    /// 特別感が薄れるため、上の節目ほど間隔が広がる階段式にしている。
    /// 熱心に借りる園児でも年5〜7回程度に収まる想定
    private enum CelebrationCounts {
        /// 同じ図書の貸出回数の節目（それ以降は祝わない）
        static let repeatedBook: Set<Int> = [5, 10]
        /// 連続週数の節目（約1ヶ月・学期・半年・通年の区切り）
        static let consecutiveWeeks: Set<Int> = [4, 12, 24, 36]
        /// 図書の種類数の節目
        static let distinctBooks: Set<Int> = [10, 30, 50]
    }
    
    /// 週の区切りの計算に使うカレンダー
    private let calendar: Calendar
    
    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }
    
    /// 新しい貸出が節目に達したかを判定する
    ///
    /// - Parameters:
    ///   - newLoan: いま作成された貸出記録
    ///   - previousLoans: 同じ利用者の過去の貸出記録（`newLoan` を含まない）
    /// - Returns: 達した節目のリスト（お祝いの優先度が高い順）。達していなければ空
    public func evaluate(newLoan: Loan, previousLoans: [Loan]) -> [LoanMilestone] {
        [
            repeatedBookMilestone(newLoan: newLoan, previousLoans: previousLoans),
            consecutiveWeeksMilestone(newLoan: newLoan, previousLoans: previousLoans),
            distinctBooksMilestone(newLoan: newLoan, previousLoans: previousLoans),
        ]
        .compactMap { $0 }
    }
    
    /// 同じ図書の繰り返し貸出の節目判定
    private func repeatedBookMilestone(newLoan: Loan, previousLoans: [Loan]) -> LoanMilestone? {
        let count = previousLoans.count(where: { $0.bookId == newLoan.bookId }) + 1
        guard CelebrationCounts.repeatedBook.contains(count) else { return nil }
        return .repeatedBook(count: count)
    }
    
    /// 連続週の貸出の節目判定
    ///
    /// `newLoan` の週から過去へ、貸出のある週が途切れず何週続いているかを数えます。
    /// 同じ週にすでに貸出があった場合は連続週数が増えていないため、節目を再判定しません。
    private func consecutiveWeeksMilestone(newLoan: Loan, previousLoans: [Loan]) -> LoanMilestone? {
        guard let newWeek = weekStart(of: newLoan.loanDate) else { return nil }
        
        let previousWeeks = Set(previousLoans.compactMap { weekStart(of: $0.loanDate) })
        guard !previousWeeks.contains(newWeek) else { return nil }
        
        var streak = 1
        var week = newWeek
        while let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: week),
            let normalized = weekStart(of: previousWeek),
            previousWeeks.contains(normalized)
        {
            streak += 1
            week = normalized
        }
        
        guard CelebrationCounts.consecutiveWeeks.contains(streak) else { return nil }
        return .consecutiveWeeks(count: streak)
    }
    
    /// 図書の種類数の節目判定
    ///
    /// 初めて借りる図書のときだけ種類数が増えるため、そのときのみ判定します。
    private func distinctBooksMilestone(newLoan: Loan, previousLoans: [Loan]) -> LoanMilestone? {
        let previousBookIds = Set(previousLoans.map(\.bookId))
        guard !previousBookIds.contains(newLoan.bookId) else { return nil }
        
        let count = previousBookIds.count + 1
        guard CelebrationCounts.distinctBooks.contains(count) else { return nil }
        return .distinctBooks(count: count)
    }
    
    /// 日付が属する週の開始日時
    private func weekStart(of date: Date) -> Date? {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start
    }
}
