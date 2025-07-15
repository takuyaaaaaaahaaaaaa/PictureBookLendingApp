import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import SwiftUI

/// 絵本貸出管理アプリのメインコンテンツビュー
///
/// タブベースのナビゲーション構造を提供し、以下の主要機能へのアクセスを提供します：
/// - 貸出（絵本から）- 絵本を選択して貸出を行う
/// - 返却・履歴（園児から）- 園児を選択して返却・履歴確認を行う
/// - 設定（管理者用）- 絵本・園児・組の管理を行う
struct ContentView: View {
    // 選択中のタブを管理
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 貸出（絵本から）タブ
            BookListContainerView()
                .tabItem {
                    Label("貸出", systemImage: "book")
                }
                .tag(0)
            
            // 返却・履歴（園児から）タブ
            ClassGroupSelectionContainerView { _ in
                // 組選択後の処理は後で実装
            }
            .tabItem {
                Label("返却・履歴", systemImage: "person.2")
            }
            .tag(1)
            
            // 設定（管理者用）タブ
            SettingsContainerView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
}

#Preview {
    // デモ用のモックモデル
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    
    ContentView()
        .environment(bookModel)
        .environment(userModel)
        .environment(lendingModel)
        .environment(classGroupModel)
}
