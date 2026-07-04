import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import SwiftUI

/// 絵本貸出管理アプリのメインコンテンツビュー
///
/// タブベースのナビゲーション構造を提供し、以下の主要機能へのアクセスを提供します：
/// - 貸出 - 図書一覧から貸出操作を行う（既定タブ）
/// - 返却 - 貸出中の利用者一覧から返却操作を行う
struct ContentView: View {
    // 選択中のタブを管理（DEBUG/リリースとも貸出タブを初期表示）
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 貸出タブ（左＝旧アプリで図書一覧が左だった並びに合わせる・オーナー決定。
            // タブ状態は自動リセットされないため既定タブの実害は小さく、並びを優先）
            BorrowListContainerView()
                .tabItem {
                    Label("貸出", systemImage: "book.circle")
                }
                .tag(0)
            
            // 返却タブ
            ReturnListContainerView()
                .tabItem {
                    Label("返却", systemImage: "arrow.uturn.backward.circle")
                }
                .tag(1)
            
            #if DEBUG
                // UIカタログタブ（開発用・DEBUGビルド限定）
                NavigationStack {
                    UICatalogContainerView()
                }
                .tabItem {
                    Label("カタログ", systemImage: "square.grid.2x2")
                }
                .tag(2)
            #endif
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
