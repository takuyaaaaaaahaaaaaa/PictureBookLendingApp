import SwiftUI
import PictureBookLendingDomain
import PictureBookLendingModel
import PictureBookLendingUI
import PictureBookLendingInfrastructure


/**
 * 貸出・返却管理のContainer View
 *
 * ビジネスロジック、状態管理、データ取得、画面制御を担当し、
 * Presentation ViewにデータとアクションHookを提供します。
 */
struct LendingContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var filterSelection = 0 // 0: 全て, 1: 貸出中, 2: 返却済み
    @State private var isNewLoanSheetPresented = false
    @State private var alertState = AlertState()
    
    private var filteredLoans: [Loan] {
        let allLoans = lendingModel.getAllLoans()
        switch filterSelection {
        case 1: // 貸出中
            return allLoans.filter { !$0.isReturned }
        case 2: // 返却済み
            return allLoans.filter { $0.isReturned }
        default: // 全て
            return allLoans
        }
    }
    
    var body: some View {
        NavigationStack {
            LendingView(
                loans: filteredLoans,
                filterSelection: $filterSelection,
                onReturn: handleReturn,
                bookModel: bookModel,
                userModel: userModel,
                lendingModel: lendingModel
            )
            .navigationTitle("貸出・返却管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isNewLoanSheetPresented = true
                    }) {
                        Label("貸出登録", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isNewLoanSheetPresented) {
                Text("新規貸出フォーム")
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
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
    }
    
    // MARK: - Actions
    
    private func refreshData() {
        bookModel.refreshBooks()
        userModel.refreshUsers()
        lendingModel.refreshLoans()
    }
    
    private func handleReturn(loanId: UUID) {
        do {
            _ = try lendingModel.returnBook(loanId: loanId)
        } catch {
            alertState = .error("返却処理に失敗しました: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let lendingModel = LendingModel(
        bookModel: bookModel,
        userModel: userModel,
        repository: mockFactory.loanRepository
    )
    
    return LendingContainerView()
        .environment(bookModel)
        .environment(userModel)
        .environment(lendingModel)
}