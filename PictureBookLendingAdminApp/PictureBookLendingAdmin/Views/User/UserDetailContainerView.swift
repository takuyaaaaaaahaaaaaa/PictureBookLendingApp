import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 利用者詳細のContainer View
///
/// ビジネスロジック、状態管理、データ取得を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct UserDetailContainerView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(LoanModel.self) private var loanModel
    @Environment(BookModel.self) private var bookModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    /// 利用者
    @State private var user: User
    /// 貸出数
    @State private var activeLoansCount = 0
    /// 貸出履歴
    @State private var loanHistory: [Loan] = []
    /// アラート状態管理
    @State private var alertState = AlertState()
    
    init(user: User) {
        self._user = State(initialValue: user)
    }
    
    var body: some View {
        UserDetailView(
            userName: $user.name,
            userClassGroupId: $user.classGroupId,
            userId: user.id,
            userType: user.userType,
            availableClassGroups: classGroupModel.classGroups,
            activeLoansCount: activeLoansCount,
            loanHistory: loanHistory,
            getBookTitle: getBookTitle,
            getClassGroupName: getClassGroupName,
            getRelatedUserName: getRelatedUserName,
            onEdit: {}
        )
        .navigationTitle(user.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("保存") {
                    saveUserChanges(user)
                }
            }
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .onAppear {
            loadUserData()
        }
    }
    
    // MARK: - Actions
    
    private func saveUserChanges(_ updatedUser: User) {
        do {
            _ = try userModel.updateUser(updatedUser)
            alertState = .success("利用者情報を保存しました")
        } catch {
            alertState = .error("利用者情報の保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    /// 絵本タイトル取得
    /// - Parameter bookId: 絵本ID
    /// - Returns: 絵本タイトル
    private func getBookTitle(for bookId: UUID) -> String {
        guard let book = bookModel.findBookById(bookId) else {
            return "不明な絵本"
        }
        return book.title
    }
    
    /// 組名取得
    /// - Parameter classGroupId: 組ID
    /// - Returns: 組名
    private func getClassGroupName(for classGroupId: UUID) -> String {
        guard let classGroup = classGroupModel.findClassGroupById(classGroupId) else {
            return "不明な組"
        }
        return classGroup.name
    }
    
    /// 関連ユーザー名取得（保護者の場合の園児名）
    /// - Parameter userId: ユーザーID
    /// - Returns: ユーザー名
    private func getRelatedUserName(for userId: UUID) -> String {
        guard let relatedUser = userModel.users.first(where: { $0.id == userId }) else {
            return "不明な利用者"
        }
        return relatedUser.name
    }
    
    /// 貸出情報取得
    private func loadUserData() {
        let activeLoans = loanModel.getActiveLoans()
        activeLoansCount = activeLoans.filter { $0.user.id == user.id }.count
        
        loanHistory = loanModel.getLoansByUser(userId: user.id)
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let userModel = UserModel(repository: mockFactory.userRepository)
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let loanModel = LoanModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository,
        loanSettingsRepository: mockFactory.loanSettingsRepository
    )
    
    let sampleUser = User(name: "山田太郎", classGroupId: UUID(), userType: .child)
    
    return NavigationStack {
        UserDetailContainerView(user: sampleUser)
            .environment(userModel)
            .environment(bookModel)
            .environment(loanModel)
    }
}
