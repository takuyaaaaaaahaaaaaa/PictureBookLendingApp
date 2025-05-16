import SwiftUI
import PictureBookLendingCore
import Observation

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
            BookListView(bookModel: bookModel)
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
    }
}

#Preview {
    // デモ用のモックモデル
    let bookModel = BookModel(repository: MockBookRepository())
    let userModel = UserModel(repository: MockUserRepository())
    let lendingModel = LendingModel(
        bookModel: bookModel,
        userModel: userModel,
        repository: MockLoanRepository()
    )
    
    ContentView(bookModel: bookModel, userModel: userModel, lendingModel: lendingModel)
}

// プレビュー用のモックリポジトリ
private class MockBookRepository: BookRepository {
    func save(_ book: Book) throws -> Book { return book }
    func fetchAll() throws -> [Book] { return [] }
    func findById(_ id: UUID) throws -> Book? { return nil }
    func update(_ book: Book) throws -> Book { return book }
    func delete(_ id: UUID) throws -> Bool { return true }
}

private class MockUserRepository: UserRepository {
    func save(_ user: User) throws -> User { return user }
    func fetchAll() throws -> [User] { return [] }
    func findById(_ id: UUID) throws -> User? { return nil }
    func update(_ user: User) throws -> User { return user }
    func delete(_ id: UUID) throws -> Bool { return true }
}

private class MockLoanRepository: LoanRepository {
    func save(_ loan: Loan) throws -> Loan { return loan }
    func fetchAll() throws -> [Loan] { return [] }
    func findById(_ id: UUID) throws -> Loan? { return nil }
    func findByBookId(_ bookId: UUID) throws -> [Loan] { return [] }
    func findByUserId(_ userId: UUID) throws -> [Loan] { return [] }
    func fetchActiveLoans() throws -> [Loan] { return [] }
    func update(_ loan: Loan) throws -> Loan { return loan }
    func delete(_ id: UUID) throws -> Bool { return true }
}