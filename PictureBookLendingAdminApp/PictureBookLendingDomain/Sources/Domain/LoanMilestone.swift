/// 貸出の節目（お祝いの対象となる記念の回数）
///
/// 貸出が記念すべき回数に達したことを表します。
/// どの回数を節目とするかの判定は `LoanMilestoneEvaluator` が行います。
public enum LoanMilestone: Equatable, Hashable, Sendable, Codable {
    /// 同じ図書を繰り返し借りた節目
    ///
    /// - Parameter count: その図書の通算貸出回数（例：5回目・10回目）
    case repeatedBook(count: Int)

    /// 連続した週で借り続けた節目
    ///
    /// - Parameter count: 連続で借りた週数（例：4週連続）
    case consecutiveWeeks(count: Int)

    /// いろいろな図書を借りた節目
    ///
    /// - Parameter count: これまでに借りた図書の種類数（例：10冊目）
    case distinctBooks(count: Int)
}
