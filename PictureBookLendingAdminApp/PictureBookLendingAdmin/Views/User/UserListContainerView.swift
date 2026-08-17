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
    @Environment(LoanModel.self) private var loanModel
    @Environment(BookModel.self) private var bookModel
    
    let classGroupId: UUID?
    
    @State private var searchText = ""
    @State private var showChildren = true
    @State private var showGuardians = false
    @State private var isAddSheetPresented = false
    @State private var alertState = AlertState()
    @State private var deleteConfirmationState = AlertState()
    @State private var navigationPath = NavigationPath()
    @State private var usersToDelete: [User] = []
    
    /// 削除確認まわりの表示用の既定値
    private enum Fallback {
        /// 貸出記録の図書が見つからない場合のタイトル表示
        static let bookTitle = "不明な図書"
    }
    
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
        .refreshable {
            userModel.refreshUsers()
        }
    }
    
    // MARK: - Actions
    
    /// 削除の確認（スワイプ削除・複数選択削除の共通入口）
    ///
    /// 借りたままの図書は削除と同時に自動返却されるため、件数の多少にかかわらず必ず確認を挟む。
    /// 確認なしに削除すると、返却する手段のない貸出（返却タブに名前だけ残り、
    /// 開いても枠が無いため返せない）が生まれ、その図書も貸出中のまま棚に戻せなくなる
    private func handleDeleteUsers(at offsets: IndexSet) {
        let users = offsets.map { filteredUsers[$0] }
        guard !users.isEmpty else { return }
        
        let selectedIds = Set(users.map(\.id))
        let targetUsers = deletionTargets(of: users)
        
        usersToDelete = users
        deleteConfirmationState = AlertState(
            isPresented: true,
            title: "利用者の削除",
            message: UserDeletionMessage.make(
                targetNames: users.map(\.name),
                cascadedGuardianNames:
                    targetUsers
                    .filter { !selectedIds.contains($0.id) }
                    .map(\.name),
                autoReturningLoans: activeLoans(of: targetUsers).map { loan in
                    UserDeletionMessage.AutoReturningLoan(
                        userName: loan.user.name,
                        bookTitle: bookModel.findBookById(loan.bookId)?.title
                            ?? Fallback.bookTitle
                    )
                }
            )
        )
    }
    
    private func executeDelete() {
        let targetUsers = usersToDelete
        usersToDelete = []
        deleteConfirmationState = AlertState()
        guard !targetUsers.isEmpty else { return }
        
        do {
            // 借りたままの図書を先に返却する
            // （先に利用者を削除すると、返却操作ができない貸出だけが残ってしまう）
            try loanModel.returnLoans(activeLoans(of: deletionTargets(of: targetUsers)))
            
            // 園児の削除で保護者も連動して消えるため、すでに消えた利用者は飛ばす
            for user in targetUsers where userModel.users.contains(where: { $0.id == user.id }) {
                _ = try userModel.deleteUser(user.id)
            }
        } catch {
            alertState = .error("利用者の削除に失敗しました", message: "\(error.localizedDescription)")
        }
    }
    
    // MARK: - 削除の波及範囲
    
    /// 削除に連動して消える利用者も含めた削除対象（重複を除き、指示された順を保つ）
    private func deletionTargets(of users: [User]) -> [User] {
        var seenIds: Set<UUID> = []
        return
            users
            .flatMap { userModel.usersDeletedTogether(with: $0.id) }
            .filter { seenIds.insert($0.id).inserted }
    }
    
    /// 指定した利用者たちが借りたままの貸出
    private func activeLoans(of users: [User]) -> [Loan] {
        users.flatMap { loanModel.getUserActiveLoans(userId: $0.id) }
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
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    // 削除時の自動返却で参照するため、貸出まわりのModelもプレビューに必要
    let loanModel = LoanModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository,
        loanSettingsRepository: mockFactory.loanSettingsRepository
    )
    
    return UserListContainerView()
        .environment(userModel)
        .environment(loanModel)
        .environment(bookModel)
}
