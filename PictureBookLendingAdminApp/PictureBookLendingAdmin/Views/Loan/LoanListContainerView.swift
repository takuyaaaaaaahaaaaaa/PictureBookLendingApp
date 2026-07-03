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
    @Environment(LoanModel.self) private var loanModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    /// 選択中の組フィルタ
    @State private var selectedGroupFilter: ClassGroup?
    /// 設定画面表示状態
    @State private var isSettingsPresented = false
    /// アラート状態
    @State private var alertState = AlertState()
    /// 成功フィードバック状態
    @State private var successFeedback = SuccessFeedback()
    /// 取り消し可能フィードバック状態
    @State private var undoFeedback = UndoFeedback()
    
    var body: some View {
        LoanListView(
            groupedLoans: groupedLoans,
            selectedGroupFilter: $selectedGroupFilter,
            groupFilterOptions: groupFilterOptions
        ) { loan in
            LoanActionContainerButton(
                bookId: loan.bookId, alertState: $alertState, successFeedback: $successFeedback,
                undoFeedback: $undoFeedback)
        }
        .navigationTitle("貸出管理")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // 設定ボタン
                // TODO: iOS26 beta6の不具合で動かない
                //SettingContainerButton()
                Button("設定", systemImage: "gearshape") {
                    isSettingsPresented = true
                }
            }
        }
        #if os(macOS)
            .sheet(isPresented: $isSettingsPresented) {
                SettingsContainerView()
            }
        #else
            .fullScreenCover(isPresented: $isSettingsPresented) {
                SettingsContainerView()
            }
        #endif
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .successFeedback($successFeedback)
        .undoFeedback($undoFeedback, onUndo: handleUndoReturn)
        .onAppear {
            selectedGroupFilter = nil  // フィルターリセット
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
    
    // MARK: - Private Methods
    
    /// フィルタを適用した貸出記録の取得
    private func applyFilters(to loans: [Loan]) -> [LoanDisplayData] {
        loans.compactMap { loan -> LoanDisplayData? in
            guard let book = bookModel.findBookById(loan.bookId) else {
                return nil
            }
            
            let user = loan.user
            // 組フィルタ適用
            if let selectedGroup = selectedGroupFilter,
                user.classGroupId != selectedGroup.id
            {
                return nil
            }
            
            let groupName = getGroupName(for: loan)
            return LoanDisplayData(
                id: loan.id,
                bookId: book.id,
                bookTitle: book.title,
                userName: user.name,
                groupName: groupName,
                loanDate: loan.loanDate,
                dueDate: loan.dueDate,
                isOverdue: loan.isOverdue(at: Date())
            )
        }
    }
    
    /// 貸出記録から組名を取得
    private func getGroupName(for loan: Loan) -> String {
        guard let classGroup = classGroupModel.findClassGroupById(loan.user.classGroupId)
        else {
            return "未分類"
        }
        return classGroup.name
    }
    
    /// 返却の取り消し（スナックバーの「元に戻す」）
    private func handleUndoReturn() {
        guard let loanId = undoFeedback.targetId else { return }
        do {
            try loanModel.undoReturn(loanId: loanId)
        } catch {
            alertState = .error("返却の取り消しに失敗しました", message: error.localizedDescription)
        }
    }
    
    /// データ更新
    private func refreshData() {
        bookModel.refreshBooks()
        loanModel.refreshLoans()
        classGroupModel.refreshClassGroups()
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
