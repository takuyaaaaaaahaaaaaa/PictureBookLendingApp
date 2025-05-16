import SwiftUI
import PictureBookLendingCore
import Observation

/**
 * 利用者一覧表示ビュー
 *
 * 登録されている全ての利用者を一覧表示し、新規追加、編集、削除などの操作を提供します。
 */
struct UserListView: View {
    let userModel: UserModel
    let lendingModel: LendingModel
    let bookModel: BookModel
    
    // 利用者の検索文字列
    @State private var searchText = ""
    
    // 新規利用者追加用のシート表示状態
    @State private var showingAddSheet = false
    
    // 現在の利用者リスト
    @State private var users: [User] = []
    
    var body: some View {
        NavigationStack {
            List {
                if !users.isEmpty {
                    ForEach(filteredUsers(users)) { user in
                        NavigationLink(destination: UserDetailView(
                            userModel: userModel,
                            lendingModel: lendingModel,
                            bookModel: bookModel,
                            user: user
                        )) {
                            UserRowView(user: user)
                        }
                    }
                    .onDelete(perform: deleteUsers)
                } else {
                    ContentUnavailableView("利用者がいません", systemImage: "person.slash", description: Text("右上の＋ボタンから利用者を登録してください"))
                }
            }
            .navigationTitle("利用者一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Label("利用者を追加", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "名前またはグループで検索")
            .sheet(isPresented: $showingAddSheet) {
                UserFormView(userModel: userModel, mode: .add, onSave: { _ in
                    loadUsers()
                })
            }
            .onAppear {
                loadUsers()
            }
            .refreshable {
                loadUsers()
            }
        }
    }
    
    // 検索フィルタリング
    private func filteredUsers(_ users: [User]) -> [User] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.group.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // 利用者リストの読み込み
    private func loadUsers() {
        users = userModel.getAllUsers()
    }
    
    // 利用者の削除処理
    private func deleteUsers(at offsets: IndexSet) {
        for index in offsets {
            let user = users[index]
            do {
                _ = try userModel.deleteUser(user.id)
            } catch {
                print("利用者の削除に失敗しました: \(error)")
            }
        }
        loadUsers()
    }
}

/**
 * 利用者リスト行ビュー
 *
 * 一覧の各行に表示する利用者情報のレイアウトを定義します。
 */
struct UserRowView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(user.name)
                .font(.headline)
            Text(user.group)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
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
    return UserListView(userModel: userModel, lendingModel: lendingModel, bookModel: bookModel)
}

// プレビュー用のモックリポジトリ
private class MockBookRepository: BookRepository {
    func save(_ book: Book) throws -> Book { return book }
    func fetchAll() throws -> [Book] { return [] }
    func findById(_ id: UUID) throws -> Book? { return nil }
    func update(_ book: Book) throws -> Book { return book }
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

// プレビュー用のモックリポジトリ
private class MockUserRepository: UserRepository {
    private var users: [User] = [
        User(name: "山田太郎", group: "1年2組"),
        User(name: "鈴木花子", group: "2年1組")
    ]
    
    func save(_ user: User) throws -> User { return user }
    func fetchAll() throws -> [User] { return users }
    func findById(_ id: UUID) throws -> User? { return users.first }
    func update(_ user: User) throws -> User { return user }
    func delete(_ id: UUID) throws -> Bool { return true }
}