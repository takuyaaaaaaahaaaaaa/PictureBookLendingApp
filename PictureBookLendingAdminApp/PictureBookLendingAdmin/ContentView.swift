import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import SwiftUI

/// 絵本貸出管理アプリのメインコンテンツビュー
///
/// タブベースのナビゲーション構造を提供し、以下の主要機能へのアクセスを提供します：
/// - 貸出（絵本から）：絵本選択からの貸出ワークフロー
/// - 返却・履歴（園児から）：園児選択からの返却・履歴管理
/// - 設定（管理者用）：管理者向けの設定・データ管理
struct ContentView: View {
    let bookModel: BookModel
    let userModel: UserModel
    let lendingModel: LendingModel
    let classGroupModel: ClassGroupModel
    
    // 選択中のタブを管理
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 貸出（絵本から）タブ
            BookLendingWorkflowContainerView()
                .tabItem {
                    Label("貸出", systemImage: "book")
                }
                .tag(0)
            
            // 返却・履歴（園児から）タブ
            UserReturnWorkflowContainerView()
                .tabItem {
                    Label("返却・履歴", systemImage: "person.2")
                }
                .tag(1)
            
            // 設定（管理者用）タブ
            AdminSettingsContainerView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(2)
        }
        .environment(bookModel)
        .environment(userModel)
        .environment(lendingModel)
        .environment(classGroupModel)
    }
}

#Preview {
    // デモ用のモックモデル
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    ContentView(
        bookModel: bookModel,
        userModel: userModel,
        lendingModel: lendingModel,
        classGroupModel: classGroupModel
    )
}
