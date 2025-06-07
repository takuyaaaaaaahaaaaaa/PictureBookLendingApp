import SwiftUI
import PictureBookLendingDomain
import Observation

/**
 * 利用者詳細表示ビュー
 *
 * 選択された利用者の詳細情報を表示し、編集や貸出履歴の確認などの機能を提供します。
 */
struct UserDetailView: View {
    let userModel: UserModel
    let lendingModel: LendingModel
    let bookModel: BookModel
    
    // 表示対象の利用者
    let user: User
    
    // 更新後の利用者情報
    @State private var updatedUser: User
    
    // 編集シート表示状態
    @State private var showingEditSheet = false
    
    // 現在の貸出数
    @State private var activeLoansCount = 0
    
    init(userModel: UserModel, lendingModel: LendingModel, bookModel: BookModel, user: User) {
        self.userModel = userModel
        self.lendingModel = lendingModel
        self.bookModel = bookModel
        self.user = user
        self._updatedUser = State(initialValue: user)
    }
    
    var body: some View {
        List {
            Section("基本情報") {
                DetailRow(label: "名前", value: updatedUser.name)
                DetailRow(label: "グループ", value: updatedUser.group)
                DetailRow(label: "管理ID", value: updatedUser.id.uuidString)
            }
            
            Section("貸出状況") {
                if activeLoansCount > 0 {
                    Text("現在 \(activeLoansCount) 冊借りています")
                        .foregroundColor(.orange)
                } else {
                    Text("貸出中の本はありません")
                        .foregroundColor(.green)
                }
            }
            
            Section("貸出履歴") {
                let loans = (try? lendingModel.getLoansByUser(userId: user.id)) ?? []
                if loans.isEmpty {
                    Text("貸出履歴はありません")
                        .italic()
                        .foregroundColor(.secondary)
                } else {
                    ForEach(loans) { loan in
                        UserLoanHistoryRow(bookModel: bookModel, loan: loan)
                    }
                }
            }
        }
        .navigationTitle(updatedUser.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            UserFormView(
                userModel: userModel,
                mode: .edit(updatedUser),
                onSave: { savedUser in
                    updatedUser = savedUser
                    checkLoanStatus()
                }
            )
        }
        .onAppear {
            checkLoanStatus()
        }
    }
    
    // 貸出状態の確認
    private func checkLoanStatus() {
        let activeLoans = lendingModel.getActiveLoans()
        activeLoansCount = activeLoans.filter { $0.userId == updatedUser.id }.count
    }
}

/**
 * 利用者の貸出履歴表示用の行コンポーネント
 */
struct UserLoanHistoryRow: View {
    let bookModel: BookModel
    let loan: Loan
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(bookTitle)
                    .font(.headline)
                Spacer()
                Image(systemName: loan.isReturned ? "checkmark.circle.fill" : "clock")
                    .foregroundColor(loan.isReturned ? .green : .orange)
            }
            
            Text("貸出日: \(formattedDate(loan.loanDate))")
                .font(.caption)
            
            if loan.isReturned, let returnedDate = loan.returnedDate {
                Text("返却日: \(formattedDate(returnedDate))")
                    .font(.caption)
            } else {
                Text("返却期限: \(formattedDate(loan.dueDate))")
                    .font(.caption)
                    .foregroundColor(isOverdue ? .red : .primary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // 書籍名の取得
    private var bookTitle: String {
        if let book = bookModel.findBookById(loan.bookId) {
            return book.title
        }
        return "不明な書籍"
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
    let bookModel = BookModel(repository: MockBookRepository())
    let userModel = UserModel(repository: MockUserRepository())
    let lendingModel = LendingModel(
        bookModel: bookModel,
        userModel: userModel,
        repository: MockLoanRepository()
    )
    let user = User(name: "山田太郎", group: "1年2組")
    
    return NavigationStack {
        UserDetailView(
            userModel: userModel,
            lendingModel: lendingModel,
            bookModel: bookModel,
            user: user
        )
    }
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