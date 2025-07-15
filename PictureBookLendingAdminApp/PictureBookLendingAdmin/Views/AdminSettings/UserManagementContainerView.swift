import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 園児管理のコンテナビュー
///
/// 既存のUserListContainerViewを管理者設定向けにラップしたビューです。
struct UserManagementContainerView: View {
    var body: some View {
        UserListContainerView()
            .navigationTitle("園児管理")
            .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let userModel = UserModel(repository: mockFactory.userRepository)
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    
    NavigationStack {
        UserManagementContainerView()
            .environment(userModel)
            .environment(classGroupModel)
    }
}