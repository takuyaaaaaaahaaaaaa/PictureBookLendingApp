import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import SwiftUI

/// 絵本貸出管理アプリのメインコンテンツビュー
///
/// タブベースのナビゲーション構造を提供し、以下の主要機能へのアクセスを提供します：
/// - 貸出（絵本から）- 貸出可能な絵本を選択して貸出を行う
/// - 返却（貸出記録から）- 貸出中の記録を組別表示して返却を行う
struct ContentView: View {
    // 選択中のタブを管理
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 貸出（絵本から）タブ
            NavigationStack {
                AvailableBookListContainerView()
            }
            .tabItem {
                Label("貸出", systemImage: "book")
            }
            .tag(0)
            
            // 返却（貸出記録から）タブ
            NavigationStack {
                LoanListContainerView()
            }
            .tabItem {
                Label("返却", systemImage: "arrow.counterclockwise")
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
