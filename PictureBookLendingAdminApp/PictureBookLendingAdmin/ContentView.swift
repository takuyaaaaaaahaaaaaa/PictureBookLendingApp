import SwiftUI
import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel

/**
 * 絵本貸出管理アプリのメインコンテンツビュー
 *
 * タブベースのナビゲーション構造を提供し、以下の主要機能へのアクセスを提供します：
 * - 絵本管理（一覧表示、追加、編集、削除）
 * - 利用者管理（一覧表示、追加、編集、削除）
 * - 貸出・返却管理（貸出、返却、履歴確認）
 * - ダッシュボード（概要情報の表示）
 */
struct ContentView: View {
    let bookModel: BookModel
    let userModel: UserModel
    let lendingModel: LendingModel
    
    // 選択中のタブを管理
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 絵本管理タブ
            BookListContainerView()
                .tabItem {
                    Label("絵本管理", systemImage: "book")
                }
                .tag(0)
            
            // 利用者管理タブ
            UserListView(userModel: userModel, lendingModel: lendingModel, bookModel: bookModel)
                .tabItem {
                    Label("利用者管理", systemImage: "person.2")
                }
                .tag(1)
            
            // 貸出・返却タブ
            LendingView(bookModel: bookModel, userModel: userModel, lendingModel: lendingModel)
                .tabItem {
                    Label("貸出・返却", systemImage: "arrow.left.arrow.right")
                }
                .tag(2)
            
            // ダッシュボードタブ
            DashboardView(bookModel: bookModel, userModel: userModel, lendingModel: lendingModel)
                .tabItem {
                    Label("ダッシュボード", systemImage: "chart.pie")
                }
                .tag(3)
        }
        .environment(bookModel)
        .environment(userModel)
        .environment(lendingModel)
    }
}

#Preview {
    // デモ用のモックモデル
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let lendingModel = LendingModel(
        bookModel: bookModel,
        userModel: userModel,
        repository: mockFactory.loanRepository
    )
    
    ContentView(bookModel: bookModel, userModel: userModel, lendingModel: lendingModel)
}