import SwiftUI
import PictureBookLendingCore

/**
 * 利用者一覧表示ビュー
 *
 * 登録されている全ての利用者を一覧表示し、新規追加、編集、削除などの操作を提供します。
 */
struct UserListView: View {
    @Environment(\.userModel) private var userModel
    
    // 利用者の検索文字列
    @State private var searchText = ""
    
    // 新規利用者追加用のシート表示状態
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                if let users = userModel?.getAllUsers(), !users.isEmpty {
                    ForEach(filteredUsers(users)) { user in
                        NavigationLink(destination: UserDetailView(user: user)) {
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
                UserFormView(mode: .add)
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
    
    // 利用者の削除処理
    private func deleteUsers(at offsets: IndexSet) {
        guard let users = userModel?.getAllUsers() else { return }
        
        for index in offsets {
            let user = users[index]
            do {
                _ = try userModel?.deleteUser(user.id)
            } catch {
                print("利用者の削除に失敗しました: \(error)")
            }
        }
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
    UserListView()
}