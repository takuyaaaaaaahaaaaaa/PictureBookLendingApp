import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 絵本管理のコンテナビュー
///
/// 既存のBookListContainerViewを管理者設定向けにラップしたビューです。
struct BookManagementContainerView: View {
    var body: some View {
        BookListContainerView()
            .navigationTitle("絵本管理")
            .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    NavigationStack {
        BookManagementContainerView()
            .environment(bookModel)
            .environment(lendingModel)
    }
}