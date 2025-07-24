import PictureBookLendingDomain
import SwiftUI

/// 利用者詳細のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct UserDetailView: View {
    @Binding var userName: String
    @Binding var userClassGroupId: UUID
    let userId: UUID
    let availableClassGroups: [ClassGroup]
    let activeLoansCount: Int
    let loanHistory: [Loan]
    let getBookTitle: (UUID) -> String
    let getClassGroupName: (UUID) -> String
    let onEdit: () -> Void
    
    public init(
        userName: Binding<String>,
        userClassGroupId: Binding<UUID>,
        userId: UUID,
        availableClassGroups: [ClassGroup],
        activeLoansCount: Int,
        loanHistory: [Loan],
        getBookTitle: @escaping (UUID) -> String,
        getClassGroupName: @escaping (UUID) -> String,
        onEdit: @escaping () -> Void
    ) {
        self._userName = userName
        self._userClassGroupId = userClassGroupId
        self.userId = userId
        self.availableClassGroups = availableClassGroups
        self.activeLoansCount = activeLoansCount
        self.loanHistory = loanHistory
        self.getBookTitle = getBookTitle
        self.getClassGroupName = getClassGroupName
        self.onEdit = onEdit
    }
    
    public var body: some View {
        List {
            Section("基本情報") {
                EditableDetailRow(label: "名前", value: $userName)
                
                EditableDetailRowWithSelection(
                    label: "グループ",
                    selectedValue: $userClassGroupId,
                    options: availableClassGroups.map(\.id),
                    displayText: getClassGroupName
                )
                
                DetailRow(label: "管理ID", value: userId.uuidString)
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

/// 利用者の貸出履歴表示用の行コンポーネント
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
            
            Text("貸出日: \(loan.loanDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
            
            if loan.isReturned, let returnedDate = loan.returnedDate {
                Text("返却日: \(returnedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
            } else {
                Text("返却期限: \(loan.dueDate.formatted(date: .abbreviated, time: .omitted))")
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
}

#Preview {
    @Previewable @State var userName = "山田太郎"
    @Previewable @State var userClassGroupId = UUID()
    
    let sampleUserId = UUID()
    let sampleClassGroups = [
        ClassGroup(id: userClassGroupId, name: "きく", ageGroup: 3, year: 2025),
        ClassGroup(id: UUID(), name: "ばら", ageGroup: 4, year: 2025),
        ClassGroup(id: UUID(), name: "さくら", ageGroup: 5, year: 2025),
    ]
    let sampleLoan = Loan(
        bookId: UUID(),
        userId: sampleUserId,
        loanDate: Date(),
        dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    )
    
    NavigationStack {
        UserDetailView(
            userName: $userName,
            userClassGroupId: $userClassGroupId,
            userId: sampleUserId,
            availableClassGroups: sampleClassGroups,
            activeLoansCount: 1,
            loanHistory: [sampleLoan],
            getBookTitle: { _ in "はらぺこあおむし" },
            getClassGroupName: { id in
                sampleClassGroups.first { $0.id == id }?.name ?? "不明"
            },
            onEdit: {}
        )
        .navigationTitle(userName)
    }
}
