import SwiftUI
import PictureBookLendingDomain

/**
 * 利用者詳細のPresentation View
 *
 * 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
 * 画面制御はContainer Viewに委譲します。
 */
public struct UserDetailView: View {
    let user: User
    let activeLoansCount: Int
    let loanHistory: [Loan]
    let getBookTitle: (UUID) -> String
    let onEdit: () -> Void
    
    public init(
        user: User,
        activeLoansCount: Int,
        loanHistory: [Loan],
        getBookTitle: @escaping (UUID) -> String,
        onEdit: @escaping () -> Void
    ) {
        self.user = user
        self.activeLoansCount = activeLoansCount
        self.loanHistory = loanHistory
        self.getBookTitle = getBookTitle
        self.onEdit = onEdit
    }
    
    public var body: some View {
        List {
            Section("基本情報") {
                DetailRow(label: "名前", value: user.name)
                DetailRow(label: "グループ", value: user.group)
                DetailRow(label: "管理ID", value: user.id.uuidString)
            }
            
            Section("貸出状況") {
                if activeLoansCount > 0 {
                    Text("現在 \(activeLoansCount) 冊借りています")
                        .foregroundStyle(.orange)
                } else {
                    Text("貸出中の本はありません")
                        .foregroundStyle(.green)
                }
            }
            
            Section("貸出履歴") {
                if loanHistory.isEmpty {
                    Text("貸出履歴はありません")
                        .italic()
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(loanHistory) { loan in
                        UserLoanHistoryRow(
                            loan: loan,
                            getBookTitle: getBookTitle
                        )
                    }
                }
            }
        }
    }
}

/**
 * 利用者の貸出履歴表示用の行コンポーネント
 */
public struct UserLoanHistoryRow: View {
    let loan: Loan
    let getBookTitle: (UUID) -> String
    
    public init(
        loan: Loan,
        getBookTitle: @escaping (UUID) -> String
    ) {
        self.loan = loan
        self.getBookTitle = getBookTitle
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(getBookTitle(loan.bookId))
                    .font(.headline)
                Spacer()
                Image(systemName: loan.isReturned ? "checkmark.circle.fill" : "clock")
                    .foregroundStyle(loan.isReturned ? .green : .orange)
            }
            
            Text("貸出日: \(formattedDate(loan.loanDate))")
                .font(.caption)
            
            if loan.isReturned, let returnedDate = loan.returnedDate {
                Text("返却日: \(formattedDate(returnedDate))")
                    .font(.caption)
            } else {
                Text("返却期限: \(formattedDate(loan.dueDate))")
                    .font(.caption)
                    .foregroundStyle(isOverdue ? .red : .primary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // 返却期限切れかどうかのチェック
    private var isOverdue: Bool {
        !loan.isReturned && Date() > loan.dueDate
    }
    
    // 日付のフォーマット
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleUser = User(name: "山田太郎", group: "1年2組")
    let sampleLoan = Loan(
        bookId: UUID(),
        userId: sampleUser.id,
        loanDate: Date(),
        dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    )
    
    NavigationStack {
        UserDetailView(
            user: sampleUser,
            activeLoansCount: 1,
            loanHistory: [sampleLoan],
            getBookTitle: { _ in "はらぺこあおむし" },
            onEdit: {}
        )
        .navigationTitle(sampleUser.name)
    }
}