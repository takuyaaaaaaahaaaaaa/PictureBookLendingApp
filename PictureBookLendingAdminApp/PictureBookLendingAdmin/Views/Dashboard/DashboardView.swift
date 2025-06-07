import SwiftUI
import PictureBookLendingDomain
import Observation

/**
 * ダッシュボードビュー
 *
 * アプリの概要情報を表示する画面です。
 * - 登録された絵本・利用者の数
 * - 現在の貸出状況
 * - 返却期限が近い貸出の警告
 * などを表示します。
 */
struct DashboardView: View {
    let bookModel: BookModel
    let userModel: UserModel
    let lendingModel: LendingModel
    
    // 統計情報
    @State private var bookCount: Int = 0
    @State private var userCount: Int = 0
    @State private var activeLoansCount: Int = 0
    @State private var overdueLoans: [Loan] = []
    
    var body: some View {
        NavigationStack {
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
                            bookModel: bookModel,
                            userModel: userModel,
                            loans: overdueLoans
                        )
                    }
                    
                    // 概要情報
                    SummaryCardsView()
                }
                .padding()
            }
            .navigationTitle("ダッシュボード")
            .onAppear {
                refreshData()
            }
            .refreshable {
                refreshData()
            }
        }
    }
    
    // データの更新
    private func refreshData() {
        bookCount = bookModel.getAllBooks().count
        userCount = userModel.getAllUsers().count
        
        let activeLoans = lendingModel.getActiveLoans()
        activeLoansCount = activeLoans.count
        
        let today = Date()
        overdueLoans = activeLoans.filter { loan in
            loan.dueDate < today
        }
    }
}

/**
 * 統計情報カードビュー
 */
struct StatisticsCardView: View {
    let bookCount: Int
    let userCount: Int
    let activeLoansCount: Int
    
    var body: some View {
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
struct StatItem: View {
    let title: String
    let count: Int
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/**
 * 返却期限切れ警告ビュー
 */
struct OverdueWarningView: View {
    let bookModel: BookModel
    let userModel: UserModel
    let loans: [Loan]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
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
                        Text(getBookTitle(for: loan.bookId))
                            .font(.subheadline)
                            .bold()
                        
                        Text(getUserName(for: loan.userId))
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("期限: \(formattedDate(loan.dueDate))")
                            .font(.caption)
                        
                        Text("\(daysSinceOverdue(loan.dueDate))日経過")
                            .font(.caption)
                            .foregroundColor(.red)
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
    
    // 書籍名の取得
    private func getBookTitle(for id: UUID) -> String {
        if let book = bookModel.findBookById(id) {
            return book.title
        }
        return "不明な書籍"
    }
    
    // 利用者名の取得
    private func getUserName(for id: UUID) -> String {
        if let user = userModel.findUserById(id) {
            return user.name
        }
        return "不明な利用者"
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
struct SummaryCardsView: View {
    var body: some View {
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
struct InfoCardView: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
    let bookModel = BookModel(repository: MockBookRepository())
    let userModel = UserModel(repository: MockUserRepository())
    let lendingModel = LendingModel(
        bookModel: bookModel,
        userModel: userModel,
        repository: MockLoanRepository()
    )
    return DashboardView(bookModel: bookModel, userModel: userModel, lendingModel: lendingModel)
}

// プレビュー用のモックリポジトリ
private class MockBookRepository: BookRepository {
    func save(_ book: Book) throws -> Book { return book }
    func fetchAll() throws -> [Book] { return [] }
    func findById(_ id: UUID) throws -> Book? { return nil }
    func update(_ book: Book) throws -> Book { return book }
    func delete(_ id: UUID) throws -> Bool { return true }
}

private class MockUserRepository: UserRepository {
    func save(_ user: User) throws -> User { return user }
    func fetchAll() throws -> [User] { return [] }
    func findById(_ id: UUID) throws -> User? { return nil }
    func update(_ user: User) throws -> User { return user }
    func delete(_ id: UUID) throws -> Bool { return true }
}

private class MockLoanRepository: LoanRepository {
    func save(_ loan: Loan) throws -> Loan { return loan }
    func fetchAll() throws -> [Loan] { return [] }
    func findById(_ id: UUID) throws -> Loan? { return nil }
    func findByBookId(_ bookId: UUID) throws -> [Loan] { return [] }
    func findByUserId(_ userId: UUID) throws -> [Loan] { return [] }
    func fetchActiveLoans() throws -> [Loan] { return [] }
    func update(_ loan: Loan) throws -> Loan { return loan }
    func delete(_ id: UUID) throws -> Bool { return true }
}
