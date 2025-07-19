import PictureBookLendingDomain
import SwiftUI

/// 貸出記録一覧のPresentation View
///
/// 組別グルーピング表示とフィルタ機能を提供します。
/// Container Viewからデータと動作を受け取り、純粋なUI表示に専念します。
public struct LoanListView: View {
    /// 組でグルーピングされた貸出記録
    public let groupedLoans: [String: [LoanDisplayData]]
    /// 選択中の組フィルタ
    @Binding public var selectedGroupFilter: String
    /// 選択中の利用者フィルタ
    @Binding public var selectedUserFilter: String
    /// 組フィルタの選択肢
    public let groupFilterOptions: [String]
    /// 利用者フィルタの選択肢
    public let userFilterOptions: [String]
    /// 返却アクション
    public let onReturn: (UUID) -> Void
    
    public init(
        groupedLoans: [String: [LoanDisplayData]],
        selectedGroupFilter: Binding<String>,
        selectedUserFilter: Binding<String>,
        groupFilterOptions: [String],
        userFilterOptions: [String],
        onReturn: @escaping (UUID) -> Void
    ) {
        self.groupedLoans = groupedLoans
        self._selectedGroupFilter = selectedGroupFilter
        self._selectedUserFilter = selectedUserFilter
        self.groupFilterOptions = groupFilterOptions
        self.userFilterOptions = userFilterOptions
        self.onReturn = onReturn
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // フィルタセクション
            filterSection
            
            // 貸出記録一覧
            if groupedLoans.isEmpty {
                emptyStateView
            } else {
                loanListSection
            }
        }
    }
    
    // MARK: - Private Views
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("組フィルタ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("組フィルタ", selection: $selectedGroupFilter) {
                    ForEach(groupFilterOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
            
            HStack {
                Text("利用者フィルタ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("利用者フィルタ", selection: $selectedUserFilter) {
                    ForEach(userFilterOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("貸出中の絵本がありません")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("絵本を貸し出すと、ここに表示されます")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loanListSection: some View {
        List {
            ForEach(sortedGroupNames, id: \.self) { groupName in
                if let loans = groupedLoans[groupName], !loans.isEmpty {
                    Section(groupName) {
                        ForEach(loans, id: \.id) { loan in
                            ReturnLoanRowView(
                                loan: loan,
                                onReturn: { onReturn(loan.id) }
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
    
    private var sortedGroupNames: [String] {
        groupedLoans.keys.sorted()
    }
}

/// 貸出記録の表示用データ構造
public struct LoanDisplayData: Identifiable, Equatable {
    public let id: UUID
    public let bookTitle: String
    public let userName: String
    public let groupName: String
    public let loanDate: Date
    public let dueDate: Date
    public let isOverdue: Bool
    
    public init(
        id: UUID,
        bookTitle: String,
        userName: String,
        groupName: String,
        loanDate: Date,
        dueDate: Date,
        isOverdue: Bool
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.userName = userName
        self.groupName = groupName
        self.loanDate = loanDate
        self.dueDate = dueDate
        self.isOverdue = isOverdue
    }
}

/// 個別の貸出記録行View（返却用）
private struct ReturnLoanRowView: View {
    let loan: LoanDisplayData
    let onReturn: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(loan.userName)
                        .font(.headline)
                    
                    if loan.isOverdue {
                        Text("延滞")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text(loan.bookTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("返却期限:")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Text(loan.dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(loan.isOverdue ? .red : .secondary)
                }
            }
            
            Spacer()
            
            Button("返却") {
                onReturn()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let sampleLoans: [String: [LoanDisplayData]] = [
        "もも組": [
            LoanDisplayData(
                id: UUID(),
                bookTitle: "はらぺこあおむし",
                userName: "田中太郎",
                groupName: "もも組",
                loanDate: Date().addingTimeInterval(-86400 * 5),
                dueDate: Date().addingTimeInterval(86400 * 9),
                isOverdue: false
            ),
            LoanDisplayData(
                id: UUID(),
                bookTitle: "ぐりとぐら",
                userName: "佐藤花子",
                groupName: "もも組",
                loanDate: Date().addingTimeInterval(-86400 * 10),
                dueDate: Date().addingTimeInterval(-86400 * 1),
                isOverdue: true
            ),
        ],
        "ひよこ組": [
            LoanDisplayData(
                id: UUID(),
                bookTitle: "おおきなかぶ",
                userName: "鈴木次郎",
                groupName: "ひよこ組",
                loanDate: Date().addingTimeInterval(-86400 * 3),
                dueDate: Date().addingTimeInterval(86400 * 11),
                isOverdue: false
            )
        ],
    ]

    LoanListView(
        groupedLoans: sampleLoans,
        selectedGroupFilter: .constant("全組"),
        selectedUserFilter: .constant("全利用者"),
        groupFilterOptions: ["全組", "もも組", "ひよこ組"],
        userFilterOptions: ["全利用者", "田中太郎", "佐藤花子", "鈴木次郎"],
        onReturn: { _ in }
    )
}
