import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 📚 貸出（絵本から）ワークフローのコンテナビュー
///
/// 絵本選択から園児選択、貸出確認までの一連のワークフローを管理します。
/// iPad横向きでの操作に最適化されたナビゲーション構造を提供します。
struct BookLendingWorkflowContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var navigationPath = NavigationPath()
    @State private var alertState = AlertState()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            BookListForLendingContainerView()
                .navigationTitle("貸出する絵本を選択")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: Book.self) { book in
                    BookDetailForLendingContainerView(book: book)
                }
                .navigationDestination(for: BookLendingDestination.self) { destination in
                    switch destination {
                    case .groupSelection(let book):
                        GroupSelectionForLendingContainerView(book: book)
                    case .userSelection(let book, let group):
                        UserSelectionForLendingContainerView(book: book, group: group)
                    case .lendingConfirmation(let book, let user):
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

/// 貸出ワークフローのナビゲーション用列挙型
enum BookLendingDestination: Hashable {
    case groupSelection(Book)
    case userSelection(Book, ClassGroup)
    case lendingConfirmation(Book, User)
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    BookLendingWorkflowContainerView()
        .environment(bookModel)
        .environment(userModel)
        .environment(classGroupModel)
        .environment(lendingModel)
}