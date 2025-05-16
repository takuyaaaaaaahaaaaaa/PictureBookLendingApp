import SwiftUI

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
    @Environment(\.bookModel) private var bookModel
    @Environment(\.userModel) private var userModel
    @Environment(\.lendingModel) private var lendingModel
    
    // 選択中のタブを管理
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 絵本管理タブ
            BookListView()
                .tabItem {
                    Label("絵本管理", systemImage: "book")
                }
                .tag(0)
            
            // 利用者管理タブ
            UserListView()
                .tabItem {
                    Label("利用者管理", systemImage: "person.2")
                }
                .tag(1)
            
            // 貸出・返却タブ
            LendingView()
                .tabItem {
                    Label("貸出・返却", systemImage: "arrow.left.arrow.right")
                }
                .tag(2)
            
            // ダッシュボードタブ
            DashboardView()
                .tabItem {
                    Label("ダッシュボード", systemImage: "chart.pie")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SwiftDataBook.self, inMemory: true)
}