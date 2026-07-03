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
    /// 貸出管理モデル
    @Environment(LoanModel.self) private var loanModel
    // 選択中のタブを管理（DEBUGビルドは開発用カタログを初期表示）
    #if DEBUG
        @State private var selectedTab = 4
    #else
        @State private var selectedTab = 0
    #endif
    
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
            .badge(overDueCount)
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
                
                // 返却モードβ（Phase 2 段取り2の動作確認用・DEBUGビルド限定）
                // 段取り4のタブ再構成で正式タブに昇格し、このDEBUGタブは撤去する
                ReturnListContainerView()
                    .tabItem {
                        Label("返却β", systemImage: "arrow.uturn.backward.circle")
                    }
                    .tag(3)
                
                // 貸出モードβ（Phase 2 段取り3の動作確認用・DEBUGビルド限定）
                // 段取り4のタブ再構成で正式タブに昇格し、このDEBUGタブは撤去する
                BorrowListContainerView()
                    .tabItem {
                        Label("貸出β", systemImage: "book.circle")
                    }
                    .tag(4)
            #endif
        }
    }
    
    /// 延滞件数
    var overDueCount: Int {
        return loanModel.getOverDueLoansCount(at: Date())
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
