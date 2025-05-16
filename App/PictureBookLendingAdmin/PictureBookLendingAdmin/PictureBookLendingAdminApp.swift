import SwiftUI
import SwiftData

@main
struct PictureBookLendingAdminApp: App {
    /// アプリで使用するSwiftDataモデルコンテナ
    var sharedModelContainer: ModelContainer
    
    /// リポジトリファクトリ
    private let repositoryFactory: RepositoryFactory
    
    /// 書籍モデル
    private let bookModel: BookModel
    
    /// 利用者モデル
    private let userModel: UserModel
    
    /// 貸出モデル
    private let lendingModel: LendingModel
    
    init() {
        // SwiftDataモデルコンテナの設定
        let schema = Schema([
            Item.self,
            SwiftDataBook.self,
            SwiftDataUser.self,
            SwiftDataLoan.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            // モデルコンテナを作成
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // リポジトリファクトリを作成
            let modelContext = sharedModelContainer.mainContext
            repositoryFactory = SwiftDataRepositoryFactory(modelContext: modelContext)
            
            // 各モデルを作成してDI
            let bookRepository = repositoryFactory.makeBookRepository()
            let userRepository = repositoryFactory.makeUserRepository()
            let loanRepository = repositoryFactory.makeLoanRepository()
            
            bookModel = BookModel(repository: bookRepository)
            userModel = UserModel(repository: userRepository)
            lendingModel = LendingModel(bookModel: bookModel, userModel: userModel, repository: loanRepository)
            
        } catch {
            fatalError("モデルコンテナの初期化に失敗しました: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.bookModel, bookModel)
                .environment(\.userModel, userModel)
                .environment(\.lendingModel, lendingModel)
        }
        .modelContainer(sharedModelContainer)
    }
}

// 環境変数キーの拡張
private struct BookModelKey: EnvironmentKey {
    static let defaultValue: BookModel? = nil
}

private struct UserModelKey: EnvironmentKey {
    static let defaultValue: UserModel? = nil
}

private struct LendingModelKey: EnvironmentKey {
    static let defaultValue: LendingModel? = nil
}

extension EnvironmentValues {
    var bookModel: BookModel? {
        get { self[BookModelKey.self] }
        set { self[BookModelKey.self] = newValue }
    }
    
    var userModel: UserModel? {
        get { self[UserModelKey.self] }
        set { self[UserModelKey.self] = newValue }
    }
    
    var lendingModel: LendingModel? {
        get { self[LendingModelKey.self] }
        set { self[LendingModelKey.self] = newValue }
    }
}