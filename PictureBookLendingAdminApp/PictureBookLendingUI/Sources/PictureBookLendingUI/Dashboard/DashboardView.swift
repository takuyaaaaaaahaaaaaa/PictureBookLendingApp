import SwiftUI
import PictureBookLendingDomain

/**
 * ダッシュボードのPresentation View
 *
 * 純粋なUI表示のみを担当し、NavigationStack、onAppear等の
 * 画面制御はContainer Viewに委譲します。
 */
public struct DashboardView: View {
    let bookCount: Int
    let userCount: Int
    let activeLoansCount: Int
    let overdueLoans: [Loan]
    let getBookTitle: (UUID) -> String
    let getUserName: (UUID) -> String
    
    public init(
        bookCount: Int,
        userCount: Int,
        activeLoansCount: Int,
        overdueLoans: [Loan],
        getBookTitle: @escaping (UUID) -> String,
        getUserName: @escaping (UUID) -> String
    ) {
        self.bookCount = bookCount
        self.userCount = userCount
        self.activeLoansCount = activeLoansCount
        self.overdueLoans = overdueLoans
        self.getBookTitle = getBookTitle
        self.getUserName = getUserName
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 統計情報カード
                StatisticsCardView(
                    bookCount: bookCount,
                    userCount: userCount,
                    activeLoansCount: activeLoansCount
                )
                
                // 期限切れ貸出の警告
                if !overdueLoans.isEmpty {
                    OverdueWarningView(
                        loans: overdueLoans,
                        getBookTitle: getBookTitle,
                        getUserName: getUserName
                    )
                }
                
                // 概要情報
                SummaryCardsView()
            }
            .padding()
        }
    }
}

/**
 * 統計情報カードビュー
 */
public struct StatisticsCardView: View {
    let bookCount: Int
    let userCount: Int
    let activeLoansCount: Int
    
    public init(bookCount: Int, userCount: Int, activeLoansCount: Int) {
        self.bookCount = bookCount
        self.userCount = userCount
        self.activeLoansCount = activeLoansCount
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("統計情報")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                StatItem(
                    title: "絵本",
                    count: bookCount,
                    iconName: "book.fill",
                    color: .blue
                )
                
                StatItem(
                    title: "利用者",
                    count: userCount,
                    iconName: "person.2.fill",
                    color: .green
                )
                
                StatItem(
                    title: "貸出中",
                    count: activeLoansCount,
                    iconName: "arrow.left.arrow.right",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

/**
 * 統計アイテムビュー
 */
public struct StatItem: View {
    let title: String
    let count: Int
    let iconName: String
    let color: Color
    
    public init(title: String, count: Int, iconName: String, color: Color) {
        self.title = title
        self.count = count
        self.iconName = iconName
        self.color = color
    }
    
    public var body: some View {
        VStack {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundStyle(color)
            
            Text("\(count)")
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/**
 * 返却期限切れ警告ビュー
 */
public struct OverdueWarningView: View {
    let loans: [Loan]
    let getBookTitle: (UUID) -> String
    let getUserName: (UUID) -> String
    
    public init(
        loans: [Loan],
        getBookTitle: @escaping (UUID) -> String,
        getUserName: @escaping (UUID) -> String
    ) {
        self.loans = loans
        self.getBookTitle = getBookTitle
        self.getUserName = getUserName
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                
                Text("返却期限切れ")
                    .font(.headline)
                
                Spacer()
                
                Text("\(loans.count)件")
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.2))
                    )
            }
            
            Divider()
            
            ForEach(loans) { loan in
                HStack {
                    VStack(alignment: .leading) {
                        Text(getBookTitle(loan.bookId))
                            .font(.subheadline)
                            .bold()
                        
                        Text(getUserName(loan.userId))
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("期限: \(formattedDate(loan.dueDate))")
                            .font(.caption)
                        
                        Text("\(daysSinceOverdue(loan.dueDate))日経過")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 4)
                
                if loan.id != loans.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    // 日付のフォーマット
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    // 期限切れ日数の計算
    private func daysSinceOverdue(_ dueDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: dueDate, to: Date())
        return max(0, components.day ?? 0)
    }
}

/**
 * 概要カードビュー
 */
public struct SummaryCardsView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("概要")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            InfoCardView(
                title: "新機能",
                description: "貸出管理アプリの使い方については「絵本の貸出管理」ボタンをタップして確認してください。",
                iconName: "star.fill",
                color: .yellow
            )
            
            InfoCardView(
                title: "貸出期間",
                description: "標準の貸出期間は14日間です。必要に応じて変更できます。",
                iconName: "calendar",
                color: .blue
            )
        }
    }
}

/**
 * 情報カードビュー
 */
public struct InfoCardView: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    
    public init(title: String, description: String, iconName: String, color: Color) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.color = color
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 30))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    let loan1 = Loan(
        bookId: UUID(),
        userId: UUID(),
        loanDate: Date(),
        dueDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
        returnedDate: nil
    )
    
    NavigationStack {
        DashboardView(
            bookCount: 150,
            userCount: 45,
            activeLoansCount: 12,
            overdueLoans: [loan1],
            getBookTitle: { _ in "サンプル本" },
            getUserName: { _ in "山田太郎" }
        )
        .navigationTitle("ダッシュボード")
    }
}

