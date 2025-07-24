import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出管理のContainer View
///
/// 組別グルーピング表示と返却機能を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct LoanListContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(LoanModel.self) private var loanModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    /// 選択中の組フィルタ
    @State private var selectedGroupFilter: ClassGroup?
    /// 選択中の利用者フィルタ
    @State private var selectedUserFilter: User?
    /// 設定画面表示状態
    @State private var isSettingsPresented = false
    /// アラート状態
    @State private var alertState = AlertState()
    
    var body: some View {
        LoanListView(
            groupedLoans: groupedLoans,
            selectedGroupFilter: $selectedGroupFilter,
            selectedUserFilter: $selectedUserFilter,
            groupFilterOptions: groupFilterOptions,
            userFilterOptions: userFilterOptions,
            onReturn: handleReturn
        )
        .navigationTitle("貸出管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("設定", systemImage: "gearshape") {
                    isSettingsPresented = true
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsContainerView()
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            if alertState.type == .success {
                Button("OK", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(alertState.message)
        }
        .onAppear {
            refreshData()
        }
        .refreshable {
            refreshData()
        }
    }
    
    // MARK: - Computed Properties
    
    /// 組でグルーピングされた貸出記録
    private var groupedLoans: [String: [LoanDisplayData]] {
        let currentLoans = loanModel.getAllLoans().filter { !$0.isReturned }
        let filteredLoans = applyFilters(to: currentLoans)
        
        return Dictionary(grouping: filteredLoans) { loan in
            loan.groupName
        }
    }
    
    /// 組フィルタの選択肢
    private var groupFilterOptions: [ClassGroup] {
        classGroupModel.getAllClassGroups()
    }
    
    /// 利用者フィルタの選択肢
    private var userFilterOptions: [User] {
        let currentLoans = loanModel.getAllLoans().filter { !$0.isReturned }
        let currentUserIds = Set(currentLoans.map { $0.userId })
        
        let users = userModel.getAllUsers().filter { user in
            currentUserIds.contains(user.id)
                && (selectedGroupFilter == nil || user.classGroupId == selectedGroupFilter?.id)
        }
        
        return users.sorted { $0.name < $1.name }
    }
    
    // MARK: - Private Methods
    
    /// フィルタを適用した貸出記録の取得
    private func applyFilters(to loans: [Loan]) -> [LoanDisplayData] {
        loans.compactMap { loan -> LoanDisplayData? in
            guard let book = bookModel.findBookById(loan.bookId),
                let user = userModel.findUserById(loan.userId)
            else {
                return nil
            }
            
            let groupName = getGroupName(for: loan)
            
            // 組フィルタ適用
            if let selectedGroup = selectedGroupFilter,
                user.classGroupId != selectedGroup.id
            {
                return nil
            }
            
            // 利用者フィルタ適用
            if let selectedUser = selectedUserFilter,
                user.id != selectedUser.id
            {
                return nil
            }
            
            return LoanDisplayData(
                id: loan.id,
                bookTitle: book.title,
                userName: user.name,
                groupName: groupName,
                loanDate: loan.loanDate,
                dueDate: loan.dueDate,
                isOverdue: loan.dueDate < Date()
            )
        }
    }
    
    /// 貸出記録から組名を取得
    private func getGroupName(for loan: Loan) -> String {
        guard let user = userModel.findUserById(loan.userId),
            let classGroup = classGroupModel.findClassGroupById(user.classGroupId)
        else {
            return "未分類"
        }
        return classGroup.name
    }
    
    /// データ更新
    private func refreshData() {
        bookModel.refreshBooks()
        userModel.refreshUsers()
        loanModel.refreshLoans()
        classGroupModel.refreshClassGroups()
    }
    
    /// 返却処理
    private func handleReturn(_ loanId: UUID) {
        do {
            _ = try loanModel.returnBook(loanId: loanId)
            alertState = .success("返却が完了しました")
        } catch {
            alertState = .error("返却処理に失敗しました: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let mockRepositoryFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockRepositoryFactory.bookRepository)
    let userModel = UserModel(repository: mockRepositoryFactory.userRepository)
    let loanModel = LoanModel(
        repository: mockRepositoryFactory.loanRepository,
        bookRepository: mockRepositoryFactory.bookRepository,
        userRepository: mockRepositoryFactory.userRepository,
        loanSettingsRepository: mockRepositoryFactory.loanSettingsRepository
    )
    let classGroupModel = ClassGroupModel(repository: mockRepositoryFactory.classGroupRepository)
    
    NavigationStack {
        LoanListContainerView()
    }
    .environment(bookModel)
    .environment(userModel)
    .environment(loanModel)
    .environment(classGroupModel)
}
