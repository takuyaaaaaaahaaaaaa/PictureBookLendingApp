import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 利用者行のContainer View
///
/// 利用者情報と関連する組名の取得を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct UserRowContainerView: View {
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    let user: User
    
    var body: some View {
        UserRowView(
            user: user,
            classGroupName: getClassGroupName(for: user.classGroupId)
        )
    }
    
    // MARK: - Helper Methods
    
    /// 組名取得
    /// - Parameter classGroupId: 組ID
    /// - Returns: 組名
    private func getClassGroupName(for classGroupId: UUID) -> String {
        guard let classGroup = classGroupModel.findClassGroupById(classGroupId) else {
            return "不明な組"
        }
        return classGroup.name
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    
    let sampleUser = User(name: "山田太郎", classGroupId: UUID())
    
    UserRowContainerView(user: sampleUser)
        .environment(classGroupModel)
}
