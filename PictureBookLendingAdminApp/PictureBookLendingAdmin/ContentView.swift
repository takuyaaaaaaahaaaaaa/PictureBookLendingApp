import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import SwiftUI

/// 絵本貸出管理アプリのメインコンテンツビュー
///
/// タブベースのナビゲーション構造を提供し、以下の主要機能へのアクセスを提供します：
/// - 絵本 - 全絵本一覧（貸出可能・貸出中を含む）
/// - 貸出管理 - 貸出中記録の組別グルーピング表示
struct ContentView: View {
    // 選択中のタブを管理
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 絵本タブ
            NavigationStack {
                BookListContainerView()
            }
            .tabItem {
                Label("絵本", systemImage: "book")
            }
            .tag(0)
            
            // 貸出管理タブ
            NavigationStack {
                LoanListContainerView()
            }
            .tabItem {
                Label("貸出管理", systemImage: "list.clipboard")
            }
            .tag(1)
        }
    }
}

#Preview {
    // デモ用のモックモデル
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let loanModel = LoanModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository,
        loanSettingsRepository: mockFactory.loanSettingsRepository
    )
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    
    ContentView()
        .environment(bookModel)
        .environment(userModel)
        .environment(loanModel)
        .environment(classGroupModel)
}
