import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 利用者一覧のContainer View
///
/// ビジネスロジック、状態管理、データ取得、画面制御を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct UserListContainerView: View {
    @Environment(UserModel.self) private var userModel
    
    @State private var searchText = ""
    @State private var isAddSheetPresented = false
    @State private var alertState = AlertState()
    @State private var navigationPath = NavigationPath()
    
    private var filteredUsers: [User] {
        return if searchText.isEmpty {
            userModel.users
        } else {
            userModel.users.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText)
                    || user.group.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            UserListView(
                users: filteredUsers,
                searchText: $searchText,
                onDelete: handleDeleteUsers
            )
            .navigationTitle("利用者一覧")
            .navigationDestination(for: User.self) { user in
                UserDetailContainerView(user: user)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddSheetPresented = true
                    }) {
                        Label("利用者を追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddSheetPresented) {
                UserFormContainerView(
                    mode: .add,
                    onSave: { _ in
                        // 追加成功時にシートを閉じる処理は既にUserFormContainerView内で実行される
                    }
                )
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertState.message)
            }
            .onAppear {
                userModel.refreshUsers()
            }
            .refreshable {
                userModel.refreshUsers()
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleDeleteUsers(at offsets: IndexSet) {
        for index in offsets {
            let user = filteredUsers[index]
            do {
                _ = try userModel.deleteUser(user.id)
            } catch {
                alertState = .error("利用者の削除に失敗しました: \(error.localizedDescription)")
            }
        }
    }
    
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    
    // プレビュー用のサンプルデータを追加
    let user1 = User(name: "山田太郎", group: "1年2組")
    let user2 = User(name: "鈴木花子", group: "2年1組")
    _ = try? mockFactory.userRepository.save(user1)
    _ = try? mockFactory.userRepository.save(user2)
    
    let userModel = UserModel(repository: mockFactory.userRepository)
    
    return UserListContainerView()
        .environment(userModel)
}
