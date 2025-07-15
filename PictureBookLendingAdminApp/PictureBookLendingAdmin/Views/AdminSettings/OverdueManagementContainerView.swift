import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 期限切れ管理のコンテナビュー
///
/// 期限切れ貸出の一覧表示と管理機能を提供します。
struct OverdueManagementContainerView: View {
    @Environment(LendingModel.self) private var lendingModel
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    
    @State private var isLoading = false
    @State private var alertState = AlertState()
    
    var body: some View {
        VStack {
            if isLoading {
                LoadingView(message: "期限切れ情報を読み込み中...")
            } else if overdueLoans.isEmpty {
                EmptyStateView(
                    title: "期限切れなし",
                    message: "現在期限切れの貸出はありません。",
                    systemImage: "checkmark.circle.fill"
                )
            } else {
                List {
                    ForEach(overdueLoans) { loan in
                        OverdueLoanRowView(
                            loan: loan,
                            book: getBook(for: loan.bookId),
                            user: getUser(for: loan.userId)
                        )
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("期限切れ管理")
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
    
    private var overdueLoans: [Loan] {
        lendingModel.currentLoans
            .filter { $0.dueDate < Date() }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    private func getBook(for bookId: UUID) -> Book? {
        bookModel.books.first { $0.id == bookId }
    }
    
    private func getUser(for userId: UUID) -> User? {
        userModel.users.first { $0.id == userId }
    }
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let loansLoad = lendingModel.load()
            async let booksLoad = bookModel.load()
            async let usersLoad = userModel.load()
            
            try await loansLoad
            try await booksLoad
            try await usersLoad
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "データの読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 期限切れ貸出行ビュー
private struct OverdueLoanRowView: View {
    let loan: Loan
    let book: Book?
    let user: User?
    
    @Environment(LendingModel.self) private var lendingModel
    @State private var alertState = AlertState()
    @State private var isReturning = false
    
    private var daysPastDue: Int {
        Calendar.current.dateComponents([.day], from: loan.dueDate, to: Date()).day ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book?.title ?? "不明な絵本")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(user?.name ?? "不明な園児")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(daysPastDue)日経過")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fontWeight(.medium)
                    
                    Button("返却処理") {
                        Task {
                            await returnBook()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                    .disabled(isReturning)
                }
            }
            
            HStack {
                Label("期限: \(loan.dueDate.formatted(date: .abbreviated, time: .omitted))", 
                      systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.red)
                
                Spacer()
                
                Label("貸出: \(loan.loanDate.formatted(date: .abbreviated, time: .omitted))", 
                      systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private func returnBook() async {
        isReturning = true
        defer { isReturning = false }
        
        do {
            try await lendingModel.returnBook(loanId: loan.id)
            alertState = AlertState(
                title: "返却完了",
                message: "期限切れ絵本の返却処理が完了しました。"
            )
        } catch {
            alertState = AlertState(
                title: "返却エラー",
                message: "返却処理に失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 空状態表示用ビュー
private struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.green)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    
    NavigationStack {
        OverdueManagementContainerView()
            .environment(lendingModel)
            .environment(bookModel)
            .environment(userModel)
    }
}