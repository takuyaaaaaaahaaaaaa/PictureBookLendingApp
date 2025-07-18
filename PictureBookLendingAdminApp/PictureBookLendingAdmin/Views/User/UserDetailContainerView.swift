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
    @Environment(LendingModel.self) private var lendingModel
    @Environment(BookModel.self) private var bookModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    /// 園児
    @State private var user: User
    /// 編集表示
    @State private var isEditSheetPresented = false
    /// 貸出数
    @State private var activeLoansCount = 0
    /// 貸出履歴
    @State private var loanHistory: [Loan] = []
    
    init(user: User) {
        self._user = State(initialValue: user)
    }
    
    var body: some View {
        UserDetailView(
            user: user,
            classGroupName: getClassGroupName(for: user.classGroupId),
            activeLoansCount: activeLoansCount,
            loanHistory: loanHistory,
            getBookTitle: getBookTitle,
            onEdit: handleEdit
        )
        .navigationTitle(user.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("編集") {
                    isEditSheetPresented = true
                }
            }
        }
        .sheet(isPresented: $isEditSheetPresented) {
            UserFormContainerView(
                mode: .edit(user),
                onSave: handleUserSaved
            )
        }
        .onAppear {
            loadUserData()
        }
    }
    
    // MARK: - Actions
    
    private func handleEdit() {
        isEditSheetPresented = true
    }
    
    private func handleUserSaved(_ savedUser: User) {
        user = savedUser
        loadUserData()
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
    
    /// 貸出情報取得
    private func loadUserData() {
        let activeLoans = lendingModel.getActiveLoans()
        activeLoansCount = activeLoans.filter { $0.userId == user.id }.count
        
        loanHistory = lendingModel.getLoansByUser(userId: user.id)
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let userModel = UserModel(repository: mockFactory.userRepository)
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    let sampleUser = User(name: "山田太郎", classGroupId: UUID())
    
    return NavigationStack {
        UserDetailContainerView(user: sampleUser)
            .environment(userModel)
            .environment(bookModel)
            .environment(lendingModel)
    }
}
