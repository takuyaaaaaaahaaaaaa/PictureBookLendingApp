import PictureBookLendingDomain
import SwiftUI

/// 貸出記録一覧のPresentation View
///
/// 組別グルーピング表示とフィルタ機能を提供します。
/// Container Viewからデータと動作を受け取り、純粋なUI表示に専念します。
public struct LoanListView<RowAction: View>: View {
    /// 組でグルーピングされた貸出記録
    public let groupedLoans: [String: [LoanDisplayData]]
    /// 選択中の組フィルタ
    @Binding public var selectedGroupFilter: ClassGroup?
    /// 選択中の利用者フィルタ
    @Binding public var selectedUserFilter: User?
    /// 組フィルタの選択肢
    public let groupFilterOptions: [ClassGroup]
    /// 利用者フィルタの選択肢
    public let userFilterOptions: [User]
    /// 各行に表示するアクションビューを生成するクロージャ
    public let rowAction: (LoanDisplayData) -> RowAction
    
    public init(
        groupedLoans: [String: [LoanDisplayData]],
        selectedGroupFilter: Binding<ClassGroup?>,
        selectedUserFilter: Binding<User?>,
        groupFilterOptions: [ClassGroup],
        userFilterOptions: [User],
        @ViewBuilder rowAction: @escaping (LoanDisplayData) -> RowAction
    ) {
        self.groupedLoans = groupedLoans
        self._selectedGroupFilter = selectedGroupFilter
        self._selectedUserFilter = selectedUserFilter
        self.groupFilterOptions = groupFilterOptions
        self.userFilterOptions = userFilterOptions
        self.rowAction = rowAction
    }
    
    public var body: some View {
        VStack(spacing: 5) {
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
        HStack(spacing: 5) {
            Picker("組フィルタ", selection: $selectedGroupFilter) {
                Text("全組").tag(nil as ClassGroup?)
                ForEach(groupFilterOptions) { group in
                    Text(group.name).tag(group as ClassGroup?)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()
            Picker("利用者フィルタ", selection: $selectedUserFilter) {
                Text("全利用者").tag(nil as User?)
                ForEach(userFilterOptions) { user in
                    Text(user.name).tag(user as User?)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()
        }
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
                            LoanListRowView(
                                loan: loan,
                                action: rowAction(loan)
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
    /// 貸出記録ID
    public let id: UUID
    /// 絵本ID
    public let bookId: UUID
    /// 絵本タイトル
    public let bookTitle: String
    /// 絵本の小さなサムネイル画像URL
    public let bookSmallThumbnail: String?
    /// 絵本のサムネイル画像URL
    public let bookThumbnail: String?
    /// 利用者名
    public let userName: String
    /// 組名
    public let groupName: String
    /// 貸出日
    public let loanDate: Date
    /// 返却期限
    public let dueDate: Date
    /// 延滞中かどうか
    public let isOverdue: Bool
    
    public init(
        id: UUID,
        bookId: UUID,
        bookTitle: String,
        bookSmallThumbnail: String? = nil,
        bookThumbnail: String? = nil,
        userName: String,
        groupName: String,
        loanDate: Date,
        dueDate: Date,
        isOverdue: Bool
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.bookSmallThumbnail = bookSmallThumbnail
        self.bookThumbnail = bookThumbnail
        self.userName = userName
        self.groupName = groupName
        self.loanDate = loanDate
        self.dueDate = dueDate
        self.isOverdue = isOverdue
    }
}

/// 個別の貸出記録行View
private struct LoanListRowView<Action: View>: View {
    /// 貸出記録データ
    let loan: LoanDisplayData
    /// 行に表示するアクションビュー
    let action: Action
    
    var body: some View {
        HStack {
            // サムネイル画像
            AsyncImage(url: URL(string: loan.bookThumbnail ?? loan.bookSmallThumbnail ?? "")) {
                image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
                    .font(.title2)
            }
            .frame(width: 50, height: 65)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
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
            
            action
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let sampleLoans: [String: [LoanDisplayData]] = [
        "もも組": [
            LoanDisplayData(
                id: UUID(),
                bookId: UUID(),
                bookTitle: "はらぺこあおむし",
                userName: "田中太郎",
                groupName: "もも組",
                loanDate: Date().addingTimeInterval(-86400 * 5),
                dueDate: Date().addingTimeInterval(86400 * 9),
                isOverdue: false
            ),
            LoanDisplayData(
                id: UUID(),
                bookId: UUID(),
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
                bookId: UUID(),
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
        selectedGroupFilter: .constant(nil),
        selectedUserFilter: .constant(nil),
        groupFilterOptions: [
            ClassGroup(name: "もも組", ageGroup: 3, year: 2024),
            ClassGroup(name: "ひよこ組", ageGroup: 2, year: 2024),
        ],
        userFilterOptions: [
            User(name: "田中太郎", classGroupId: UUID()),
            User(name: "佐藤花子", classGroupId: UUID()),
            User(name: "鈴木次郎", classGroupId: UUID()),
        ],
    ) { loan in
        ReturnButtonView(onTap: {})
    }
}
