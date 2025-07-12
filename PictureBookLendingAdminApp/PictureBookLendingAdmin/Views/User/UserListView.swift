import SwiftUI
import PictureBookLendingInfrastructure
import PictureBookLendingDomain
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
    let mockFactory = MockRepositoryFactory()
    
    // プレビュー用のサンプルデータを追加
    let user1 = User(name: "山田太郎", group: "1年2組")
    let user2 = User(name: "鈴木花子", group: "2年1組")
    try? mockFactory.userRepository.save(user1)
    try? mockFactory.userRepository.save(user2)
    
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let lendingModel = LendingModel(
        bookModel: bookModel,
        userModel: userModel,
        repository: mockFactory.loanRepository
    )
    return UserListView(userModel: userModel, lendingModel: lendingModel, bookModel: bookModel)
}
