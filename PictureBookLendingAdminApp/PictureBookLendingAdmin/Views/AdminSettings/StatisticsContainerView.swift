import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 統計情報のコンテナビュー
///
/// アプリ全体の利用統計情報を表示します。
struct StatisticsContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var isLoading = false
    @State private var alertState = AlertState()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    LoadingView(message: "統計データを読み込み中...")
                } else {
                    basicStatsSection
                    lendingStatsSection
                    popularBooksSection
                }
            }
            .padding()
        }
        .navigationTitle("統計情報")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private var basicStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本統計")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCardView(
                    title: "総絵本数",
                    value: "\(bookModel.books.count)",
                    icon: "book.fill",
                    color: .blue
                )
                
                StatCardView(
                    title: "総園児数",
                    value: "\(userModel.users.count)",
                    icon: "person.fill",
                    color: .green
                )
                
                StatCardView(
                    title: "組数",
                    value: "\(classGroupModel.classGroups.count)",
                    icon: "person.3.fill",
                    color: .purple
                )
                
                StatCardView(
                    title: "貸出中",
                    value: "\(lendingModel.currentLoans.count)",
                    icon: "book.and.wrench",
                    color: .orange
                )
            }
        }
    }
    
    private var lendingStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("貸出統計")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCardView(
                    title: "総貸出回数",
                    value: "\(lendingModel.loanHistory.count)",
                    icon: "arrow.up.circle.fill",
                    color: .blue
                )
                
                StatCardView(
                    title: "期限切れ",
                    value: "\(overdueCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                StatCardView(
                    title: "今月の貸出",
                    value: "\(thisMonthLoanCount)",
                    icon: "calendar",
                    color: .indigo
                )
                
                StatCardView(
                    title: "返却率",
                    value: "\(returnRate)%",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
    }
    
    private var popularBooksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("人気絵本TOP5")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(Array(popularBooks.enumerated()), id: \.offset) { index, bookData in
                    HStack {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bookData.book.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(bookData.book.author)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(bookData.loanCount)回")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
    
    private var overdueCount: Int {
        lendingModel.currentLoans.filter { $0.dueDate < Date() }.count
    }
    
    private var thisMonthLoanCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return lendingModel.loanHistory.filter { loan in
            calendar.isDate(loan.loanDate, equalTo: now, toGranularity: .month)
        }.count
    }
    
    private var returnRate: Int {
        let totalLoans = lendingModel.loanHistory.count
        let returnedLoans = lendingModel.loanHistory.filter { $0.returnDate != nil }.count
        return totalLoans > 0 ? Int((Double(returnedLoans) / Double(totalLoans)) * 100) : 0
    }
    
    private var popularBooks: [(book: Book, loanCount: Int)] {
        let loanCounts = Dictionary(grouping: lendingModel.loanHistory) { $0.bookId }
            .mapValues { $0.count }
        
        return bookModel.books
            .compactMap { book in
                let count = loanCounts[book.id] ?? 0
                return count > 0 ? (book, count) : nil
            }
            .sorted { $0.loanCount > $1.loanCount }
            .prefix(5)
            .map { $0 }
    }
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let booksLoad = bookModel.load()
            async let usersLoad = userModel.load()
            async let groupsLoad = classGroupModel.load()
            async let loansLoad = lendingModel.load()
            
            try await booksLoad
            try await usersLoad
            try await groupsLoad
            try await loansLoad
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "統計データの読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 統計カードビュー
private struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    NavigationStack {
        StatisticsContainerView()
            .environment(bookModel)
            .environment(userModel)
            .environment(classGroupModel)
            .environment(lendingModel)
    }
}