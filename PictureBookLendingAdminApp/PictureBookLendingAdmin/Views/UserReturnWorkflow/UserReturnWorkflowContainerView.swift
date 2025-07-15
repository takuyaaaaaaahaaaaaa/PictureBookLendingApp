import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 👦 返却・履歴（園児から）ワークフローのコンテナビュー
///
/// 組選択から園児選択、返却・履歴確認までの一連のワークフローを管理します。
/// iPad横向きでの操作に最適化されたナビゲーション構造を提供します。
struct UserReturnWorkflowContainerView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LendingModel.self) private var lendingModel
    @Environment(BookModel.self) private var bookModel
    
    @State private var navigationPath = NavigationPath()
    @State private var alertState = AlertState()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GroupSelectionForReturnContainerView()
                .navigationTitle("組を選択")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: ClassGroup.self) { group in
                    UserListFromGroupContainerView(group: group)
                }
                .navigationDestination(for: UserReturnDestination.self) { destination in
                    switch destination {
                    case .userDetail(let user):
                        UserDetailForReturnContainerView(user: user)
                    case .newLendingForUser(let user):
                        BookSelectionForUserContainerView(user: user)
                    case .lendingConfirmationForUser(let book, let user):
                        LendingConfirmationContainerView(book: book, user: user)
                    }
                }
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
}

/// 返却ワークフローのナビゲーション用列挙型
enum UserReturnDestination: Hashable {
    case userDetail(User)
    case newLendingForUser(User)
    case lendingConfirmationForUser(Book, User)
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let userModel = UserModel(repository: mockFactory.userRepository)
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    
    UserReturnWorkflowContainerView()
        .environment(userModel)
        .environment(classGroupModel)
        .environment(lendingModel)
        .environment(bookModel)
}