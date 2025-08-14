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
    @Environment(LoanModel.self) private var loanModel
    
    // 選択中のタブを管理
    @State private var selectedTab = 0
    // 返却期限切れの貸出件数
    @State private var overdueCount = 0
    
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
            .badge(overdueCount > 0 ? overdueCount : nil)
            .tag(1)
            
            // 絵本登録タブ（新規追加）
            NavigationStack {
                BookSearchContainerView()
            }
            .tabItem {
                Label("絵本登録", systemImage: "plus.circle")
            }
            .tag(2)
        }
        .onAppear {
            updateOverdueCount()
        }
        .onChange(of: selectedTab) { _, _ in
            updateOverdueCount()
        }
    }
    
    // MARK: - Private Methods
    
    /// 返却期限切れの貸出件数を更新する
    private func updateOverdueCount() {
        overdueCount = loanModel.getOverdueLoansCount()
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
