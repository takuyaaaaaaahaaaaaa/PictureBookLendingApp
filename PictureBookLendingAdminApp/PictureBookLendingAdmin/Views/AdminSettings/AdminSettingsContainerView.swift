import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// ⚙️ 設定（管理者用）のコンテナビュー
///
/// 管理者向けの設定画面を提供します：
/// - 組管理（一覧／新規登録／編集／削除）
/// - 園児管理（一覧／新規登録／編集／削除）
/// - 絵本管理（一覧／新規登録／編集／削除）
/// - 統計情報
/// - 期限切れ管理
/// - アプリ設定
/// - データ同期
struct AdminSettingsContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var navigationPath = NavigationPath()
    @State private var alertState = AlertState()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            AdminSettingsMenuView()
                .navigationTitle("管理者設定")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: AdminSettingsDestination.self) { destination in
                    switch destination {
                    case .groupManagement:
                        GroupManagementContainerView()
                    case .userManagement:
                        UserManagementContainerView()
                    case .bookManagement:
                        BookManagementContainerView()
                    case .statistics:
                        StatisticsContainerView()
                    case .overdueManagement:
                        OverdueManagementContainerView()
                    case .appSettings:
                        AppSettingsContainerView()
                    case .dataSync:
                        DataSyncContainerView()
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

/// 管理者設定のナビゲーション用列挙型
enum AdminSettingsDestination: Hashable, CaseIterable {
    case groupManagement
    case userManagement
    case bookManagement
    case statistics
    case overdueManagement
    case appSettings
    case dataSync
    
    var title: String {
        switch self {
        case .groupManagement: "組管理"
        case .userManagement: "園児管理"
        case .bookManagement: "絵本管理"
        case .statistics: "統計情報"
        case .overdueManagement: "期限切れ管理"
        case .appSettings: "アプリ設定"
        case .dataSync: "データ同期"
        }
    }
    
    var iconName: String {
        switch self {
        case .groupManagement: "person.3"
        case .userManagement: "person.circle"
        case .bookManagement: "books.vertical"
        case .statistics: "chart.bar"
        case .overdueManagement: "exclamationmark.triangle"
        case .appSettings: "gear"
        case .dataSync: "arrow.triangle.2.circlepath"
        }
    }
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
    
    AdminSettingsContainerView()
        .environment(bookModel)
        .environment(userModel)
        .environment(classGroupModel)
        .environment(lendingModel)
}