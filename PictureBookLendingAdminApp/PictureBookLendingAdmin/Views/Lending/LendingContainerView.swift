import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出・返却管理のContainer View
///
/// ビジネスロジック、状態管理、データ取得、画面制御を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct LendingContainerView: View {
    /// 貸出フィルタの種類
    private enum FilterType: Int, CaseIterable {
        case all = 0
        case lent = 1
        case returned = 2
        
        var title: String {
            switch self {
            case .all: "全て"
            case .lent: "貸出中"
            case .returned: "返却済み"
            }
        }
    }
    
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(LoanModel.self) private var loanModel
    
    @State private var filterSelection = FilterType.all
    @State private var isNewLoanSheetPresented = false
    @State private var alertState = AlertState()
    
    private var filteredLoans: [Loan] {
        let allLoans = loanModel.getAllLoans()
        return switch filterSelection {
        case .lent:
            allLoans.filter { !$0.isReturned }
        case .returned:
            allLoans.filter { $0.isReturned }
        case .all:
            allLoans
        }
    }
    
    var body: some View {
        NavigationStack {
            LendingView(
                loans: filteredLoans,
                filterSelection: Binding(
                    get: { filterSelection.rawValue },
                    set: { filterSelection = FilterType(rawValue: $0) ?? .all }
                ),
                onReturn: handleReturn,
                getBookTitle: { bookModel.findBookById($0)?.title ?? "不明な絵本" },
                getUserName: { userModel.findUserById($0)?.name ?? "不明な利用者" }
            )
            .navigationTitle("貸出・返却管理")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        isNewLoanSheetPresented = true
                    }) {
                        Label("貸出登録", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isNewLoanSheetPresented) {
                NewLoanContainerView()
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
        loanModel.refreshLoans()
    }
    
    private func handleReturn(loanId: UUID) {
        do {
            _ = try loanModel.returnBook(loanId: loanId)
        } catch {
            alertState = .error("返却処理に失敗しました: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let loanModel = LoanModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    return LendingContainerView()
        .environment(bookModel)
        .environment(userModel)
        .environment(loanModel)
}
