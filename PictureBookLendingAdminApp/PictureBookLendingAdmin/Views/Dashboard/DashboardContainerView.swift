import SwiftUI
import PictureBookLendingDomain
import PictureBookLendingModel
import PictureBookLendingUI
import PictureBookLendingInfrastructure


/**
 * ダッシュボードのContainer View
 *
 * ビジネスロジック、状態管理、データ取得を担当し、
 * Presentation ViewにデータとアクションHookを提供します。
 */
struct DashboardContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var bookCount = 0
    @State private var userCount = 0
    @State private var activeLoansCount = 0
    @State private var overdueLoans: [Loan] = []
    
    var body: some View {
        NavigationStack {
            DashboardView(
                bookCount: bookCount,
                userCount: userCount,
                activeLoansCount: activeLoansCount,
                overdueLoans: overdueLoans,
                bookModel: bookModel,
                userModel: userModel
            )
            .navigationTitle("ダッシュボード")
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
        bookCount = bookModel.getAllBooks().count
        userCount = userModel.getAllUsers().count
        
        let activeLoans = lendingModel.getActiveLoans()
        activeLoansCount = activeLoans.count
        
        let today = Date()
        overdueLoans = activeLoans.filter { loan in
            loan.dueDate < today
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    return DashboardContainerView()
        .environment(bookModel)
        .environment(userModel)
        .environment(lendingModel)
}