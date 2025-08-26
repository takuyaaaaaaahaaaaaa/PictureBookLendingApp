import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 利用者一覧のContainer View
///
/// ビジネスロジック、状態管理、データ取得、画面制御を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
/// 組IDが指定された場合は、その組の利用者のみ表示します。
struct UserListContainerView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    let classGroupId: UUID?
    
    @State private var searchText = ""
    @State private var showChildren = true
    @State private var showGuardians = false
    @State private var isAddSheetPresented = false
    @State private var alertState = AlertState()
    @State private var deleteConfirmationState = AlertState()
    @State private var navigationPath = NavigationPath()
    @State private var userToDelete: User?
    
    init(classGroupId: UUID? = nil) {
        self.classGroupId = classGroupId
    }
    
    private var filteredUsers: [User] {
        let usersInGroup =
            if let classGroupId = classGroupId {
                userModel.users.filter { $0.classGroupId == classGroupId }
            } else {
                userModel.users
            }
        
        // 利用者種別によるフィルタリング
        let usersByType = usersInGroup.filter { user in
            switch user.userType {
            case .child:
                return showChildren
            case .guardian:
                return showGuardians
            }
        }
        
        // 検索テキストによるフィルタリング
        return if searchText.isEmpty {
            usersByType
        } else {
            usersByType.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var navigationTitle: String {
        if let classGroupId = classGroupId,
            let classGroup = classGroupModel.findClassGroupById(classGroupId)
        {
            "\(classGroup.name)の利用者"
        } else {
            "利用者一覧"
        }
    }
    
    var body: some View {
        UserListView(
            users: filteredUsers,
            searchText: $searchText,
            showChildren: $showChildren,
            showGuardians: $showGuardians,
            onDelete: handleDeleteUsers
        ) { user in
            UserRowContainerView(user: user)
        }
        .navigationTitle(navigationTitle)
        .navigationDestination(for: User.self) { user in
            UserDetailContainerView(user: user)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isAddSheetPresented = true
                }) {
                    Label("利用者を追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddSheetPresented) {
            UserFormContainerView(
                initialClassGroupId: classGroupId
            )
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .alert(deleteConfirmationState.title, isPresented: $deleteConfirmationState.isPresented) {
            Button("削除", role: .destructive) {
                executeDelete()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text(deleteConfirmationState.message)
        }
        .onAppear {
            userModel.refreshUsers()
        }
        .refreshable {
            userModel.refreshUsers()
        }
    }
    
    // MARK: - Actions
    
    private func handleDeleteUsers(at offsets: IndexSet) {
        guard let index = offsets.first, offsets.count == 1 else {
            // 複数選択の場合は通常の削除処理
            for index in offsets {
                let user = filteredUsers[index]
                do {
                    _ = try userModel.deleteUser(user.id)
                } catch {
                    alertState = .error("利用者の削除に失敗しました: \(error.localizedDescription)")
                }
            }
            return
        }
        
        let user = filteredUsers[index]
        userToDelete = user
        
        // 園児かつ関連保護者がいる場合をチェック
        let isChildAndHasGuardians =
            user.userType == .child
            && userModel.users.contains { child in
                if case .guardian(let relatedChildId) = child.userType {
                    return relatedChildId == child.id
                }
                return false
            }
        
        let message =
            if isChildAndHasGuardians {
                "\(user.name)を削除しますか？\n関連する保護者も合わせて削除されます。"
            } else {
                "\(user.name)を削除しますか？"
            }
        
        deleteConfirmationState = AlertState(
            isPresented: true,
            title: "利用者の削除",
            message: message
        )
    }
    
    private func executeDelete() {
        guard let user = userToDelete else { return }
        
        do {
            _ = try userModel.deleteUser(user.id)
        } catch {
            alertState = .error("利用者の削除に失敗しました: \(error.localizedDescription)")
        }
        
        userToDelete = nil
        deleteConfirmationState = AlertState()
    }
}

#Preview {
    // プレビュー用のサンプルデータを追加
    let mockFactory = MockRepositoryFactory()
    let user1 = User(name: "山田太郎", classGroupId: UUID())
    let user2 = User(name: "鈴木花子", classGroupId: UUID())
    
    // リポジトリにサンプルデータを追加
    _ = try? mockFactory.userRepository.save(user1)
    _ = try? mockFactory.userRepository.save(user2)
    
    let userModel = UserModel(repository: mockFactory.userRepository)
    
    return UserListContainerView()
        .environment(userModel)
}
