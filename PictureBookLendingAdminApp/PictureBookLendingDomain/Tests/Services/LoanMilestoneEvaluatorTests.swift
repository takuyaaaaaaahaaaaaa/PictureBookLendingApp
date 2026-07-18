import Foundation
import Testing

@testable import PictureBookLendingDomain

/// LoanMilestoneEvaluatorテストケース
///
/// 貸出の節目（同じ図書の繰り返し・連続週・図書の種類数）の判定をテストします。
@Suite("LoanMilestoneEvaluator Tests")
struct LoanMilestoneEvaluatorTests {

    /// テストの基準日（2026-01-15 木曜日 12:00 UTC）
    private static let baseDate = Date(timeIntervalSince1970: 1_768_478_400)

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private let user = User(name: "山田太郎", classGroupId: UUID())

    private var evaluator: LoanMilestoneEvaluator {
        LoanMilestoneEvaluator(calendar: calendar)
    }

    /// 基準日から週数をずらした日付で貸出記録を作る
    private func makeLoan(bookId: UUID, weeksAgo: Int = 0, daysOffset: Int = 0) -> Loan {
        var loanDate = calendar.date(
            byAdding: .weekOfYear, value: -weeksAgo, to: Self.baseDate)!
        loanDate = calendar.date(byAdding: .day, value: daysOffset, to: loanDate)!
        let dueDate = calendar.date(byAdding: .day, value: 14, to: loanDate)!
        return Loan(bookId: bookId, user: user, loanDate: loanDate, dueDate: dueDate)
    }

    // MARK: - 節目なし

    @Test("初回の貸出は節目に達しない")
    func firstLoanHasNoMilestone() {
        let bookId = UUID()
        let newLoan = makeLoan(bookId: bookId)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: [])

        #expect(milestones.isEmpty)
    }

    // MARK: - 同じ図書の繰り返し

    @Test("同じ図書の5回目の貸出で節目に達する")
    func fifthLoanOfSameBookReachesMilestone() {
        let bookId = UUID()
        let previousLoans = (1...4).map { makeLoan(bookId: bookId, weeksAgo: 0, daysOffset: -$0) }
        let newLoan = makeLoan(bookId: bookId)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(milestones == [.repeatedBook(count: 5)])
    }

    @Test("同じ図書の4回目の貸出は節目に達しない")
    func fourthLoanOfSameBookHasNoMilestone() {
        let bookId = UUID()
        let previousLoans = (1...3).map { makeLoan(bookId: bookId, weeksAgo: 0, daysOffset: -$0) }
        let newLoan = makeLoan(bookId: bookId)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(milestones.isEmpty)
    }

    @Test("同じ図書の10回目の貸出で節目に達する")
    func tenthLoanOfSameBookReachesMilestone() {
        let bookId = UUID()
        let previousLoans = (1...9).map { makeLoan(bookId: bookId, weeksAgo: 0, daysOffset: -$0) }
        let newLoan = makeLoan(bookId: bookId)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(milestones == [.repeatedBook(count: 10)])
    }

    // MARK: - 図書の種類数

    @Test("10種類目の図書の貸出で節目に達する")
    func tenthDistinctBookReachesMilestone() {
        let previousLoans = (1...9).map { _ in makeLoan(bookId: UUID(), daysOffset: -1) }
        let newLoan = makeLoan(bookId: UUID())

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(milestones == [.distinctBooks(count: 10)])
    }

    @Test("借りたことのある図書では種類数の節目に達しない")
    func alreadyBorrowedBookDoesNotIncreaseDistinctCount() {
        let knownBookId = UUID()
        var previousLoans = (1...8).map { _ in makeLoan(bookId: UUID(), daysOffset: -2) }
        previousLoans.append(makeLoan(bookId: knownBookId, daysOffset: -1))
        // 種類数は9のまま（10冊目にはならない）
        let newLoan = makeLoan(bookId: knownBookId)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(!milestones.contains(.distinctBooks(count: 10)))
    }

    @Test("同じ図書を10回借りても種類数の節目には達しない")
    func repeatedLoansDoNotCountAsDistinctBooks() {
        let bookId = UUID()
        let previousLoans = (1...9).map { makeLoan(bookId: bookId, weeksAgo: 0, daysOffset: -$0) }
        let newLoan = makeLoan(bookId: bookId)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(milestones == [.repeatedBook(count: 10)])
    }

    // MARK: - 連続週の貸出

    @Test("4週連続の貸出で節目に達する")
    func fourConsecutiveWeeksReachesMilestone() {
        let previousLoans = (1...3).map { makeLoan(bookId: UUID(), weeksAgo: $0) }
        let newLoan = makeLoan(bookId: UUID(), weeksAgo: 0)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(milestones == [.consecutiveWeeks(count: 4)])
    }

    @Test("3週連続の貸出は節目に達しない")
    func threeConsecutiveWeeksHasNoMilestone() {
        let previousLoans = (1...2).map { makeLoan(bookId: UUID(), weeksAgo: $0) }
        let newLoan = makeLoan(bookId: UUID(), weeksAgo: 0)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(milestones.isEmpty)
    }

    @Test("週が途切れると連続週数はリセットされる")
    func gapWeekResetsStreak() {
        // 4週前・3週前に借りたが、2週前・1週前は借りていない
        let previousLoans = [
            makeLoan(bookId: UUID(), weeksAgo: 4),
            makeLoan(bookId: UUID(), weeksAgo: 3),
        ]
        let newLoan = makeLoan(bookId: UUID(), weeksAgo: 0)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(milestones.isEmpty)
    }

    @Test("同じ週の2回目の貸出では連続週の節目を再判定しない")
    func secondLoanInSameWeekDoesNotRetrigger() {
        // 3週前〜今週まで毎週借りていて、今週はすでに1回借りている
        let previousLoans = (0...3).map { makeLoan(bookId: UUID(), weeksAgo: $0, daysOffset: -1) }
        let newLoan = makeLoan(bookId: UUID(), weeksAgo: 0)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(milestones.isEmpty)
    }

    // MARK: - 複数の節目

    @Test("複数の節目に同時に達した場合は優先度順に返す")
    func multipleMilestonesAreOrderedByPriority() {
        let bookId = UUID()
        // 同じ図書を3週前・2週前・1週前・1週前の計4回借りていて、今週5回目を借りる
        // → 同じ図書5回目＋4週連続の両方に達する
        let previousLoans = [
            makeLoan(bookId: bookId, weeksAgo: 3),
            makeLoan(bookId: bookId, weeksAgo: 2),
            makeLoan(bookId: bookId, weeksAgo: 1),
            makeLoan(bookId: bookId, weeksAgo: 1, daysOffset: 1),
        ]
        let newLoan = makeLoan(bookId: bookId, weeksAgo: 0)

        let milestones = evaluator.evaluate(newLoan: newLoan, previousLoans: previousLoans)

        #expect(milestones == [.repeatedBook(count: 5), .consecutiveWeeks(count: 4)])
    }
}
