import PictureBookLendingDomain
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 返却用園児詳細のコンテナビュー
///
/// 選択された園児の詳細情報、貸出中絵本、履歴を表示し、
/// 返却処理や新規貸出を行うことができる画面です。
struct UserDetailForReturnContainerView: View {
    let user: User
    
    @Environment(LendingModel.self) private var lendingModel
    @Environment(BookModel.self) private var bookModel
    @Environment(\.navigationPath) private var navigationPath
    
    @State private var selectedTab = 0
    @State private var alertState = AlertState()
    @State private var isLoading = false
    @State private var isProcessingReturn = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 園児情報ヘッダー
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("年齢: \(user.age)歳")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if currentLoans.count > 0 {
                            Label("\(currentLoans.count)冊貸出中", systemImage: "book.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else {
                            Label("貸出なし", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Spacer()
                
                // 新規貸出ボタン
                Button("新規貸出") {
                    navigationPath.wrappedValue.append(UserReturnDestination.newLendingForUser(user))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            
            // タブセレクター
            Picker("表示内容", selection: $selectedTab) {
                Text("貸出中(\(currentLoans.count))").tag(0)
                Text("履歴").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // コンテンツ
            TabView(selection: $selectedTab) {
                // 貸出中絵本タブ
                currentLoansView
                    .tag(0)
                
                // 履歴タブ
                historyView
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(user.name)
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
    
    private var currentLoans: [Loan] {
        lendingModel.currentLoans.filter { $0.userId == user.id }
    }
    
    private var loanHistory: [Loan] {
        lendingModel.loanHistory.filter { $0.userId == user.id }
    }
    
    private var currentLoansView: some View {
        Group {
            if currentLoans.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("貸出中の絵本はありません")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\(user.name)くん/ちゃんは現在絵本を借りていません。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("新しい絵本を貸し出す") {
                        navigationPath.wrappedValue.append(UserReturnDestination.newLendingForUser(user))
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(currentLoans) { loan in
                            CurrentLoanCardView(
                                loan: loan,
                                book: getBook(for: loan.bookId),
                                onReturn: { await returnBook(loan) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var historyView: some View {
        Group {
            if loanHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("貸出履歴がありません")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\(user.name)くん/ちゃんの貸出履歴はまだありません。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(loanHistory.sorted { $0.loanDate > $1.loanDate }) { loan in
                            LoanHistoryCardView(
                                loan: loan,
                                book: getBook(for: loan.bookId)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private func getBook(for bookId: UUID) -> Book? {
        bookModel.books.first { $0.id == bookId }
    }
    
    private func returnBook(_ loan: Loan) async {
        isProcessingReturn = true
        defer { isProcessingReturn = false }
        
        do {
            try await lendingModel.returnBook(loanId: loan.id)
            alertState = AlertState(
                title: "返却完了",
                message: "絵本の返却が完了しました。"
            )
        } catch {
            alertState = AlertState(
                title: "返却エラー",
                message: "返却処理に失敗しました: \(error.localizedDescription)"
            )
        }
    }
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await lendingModel.load()
            try await bookModel.load()
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "データの読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 貸出中絵本カードビュー
private struct CurrentLoanCardView: View {
    let loan: Loan
    let book: Book?
    let onReturn: () async -> Void
    
    @State private var isReturning = false
    
    private var isOverdue: Bool {
        loan.dueDate < Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book?.title ?? "不明な絵本")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let book = book {
                        Text("著者: \(book.author)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if isOverdue {
                    Label("期限切れ", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("貸出日: \(loan.loanDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("返却期限: \(loan.dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(isOverdue ? .red : .secondary)
                }
                
                Spacer()
                
                Button("返却") {
                    Task {
                        await onReturn()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isReturning)
                .tint(isOverdue ? .red : .blue)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isOverdue ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

/// 貸出履歴カードビュー
private struct LoanHistoryCardView: View {
    let loan: Loan
    let book: Book?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(book?.title ?? "不明な絵本")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let book = book {
                    Text("著者: \(book.author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("貸出: \(loan.loanDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let returnDate = loan.returnDate {
                        Text("返却: \(returnDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if loan.returnDate != nil {
                Label("返却済み", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
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
    
    let sampleUser = User(
        id: UUID(),
        name: "田中太郎",
        age: 5,
        classGroupId: UUID()
    )
    
    NavigationStack {
        UserDetailForReturnContainerView(user: sampleUser)
            .environment(lendingModel)
            .environment(bookModel)
    }
}