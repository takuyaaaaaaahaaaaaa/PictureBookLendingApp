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
    
    let initialUser: User
    
    @State private var user: User
    @State private var isEditSheetPresented = false
    @State private var activeLoansCount = 0
    @State private var loanHistory: [Loan] = []
    
    init(user: User) {
        self.initialUser = user
        self._user = State(initialValue: user)
    }
    
    var body: some View {
        UserDetailView(
            user: user,
            activeLoansCount: activeLoansCount,
            loanHistory: loanHistory,
            getBookTitle: getBookTitle,
            onEdit: handleEdit
        )
        .navigationTitle(user.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
    
    private func getBookTitle(for bookId: UUID) -> String {
        guard let book = bookModel.findBookById(bookId) else {
            return "不明な絵本"
        }
        return book.title
    }
    
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
    
    let sampleUser = User(name: "山田太郎", group: "1年2組")
    
    return NavigationStack {
        UserDetailContainerView(user: sampleUser)
            .environment(userModel)
            .environment(bookModel)
            .environment(lendingModel)
    }
}
