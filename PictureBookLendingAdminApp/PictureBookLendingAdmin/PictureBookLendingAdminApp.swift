import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import SwiftData
import SwiftUI

@main
struct PictureBookLendingAdminApp: App {
    /// アプリで使用するSwiftDataモデルコンテナ
    var sharedModelContainer: ModelContainer
    
    /// リポジトリファクトリ
    private let repositoryFactory: RepositoryFactory
    
    /// 絵本モデル
    private let bookModel: BookModel
    
    /// 利用者モデル
    private let userModel: UserModel
    
    /// 貸出モデル
    private let lendingModel: LendingModel
    
    init() {
        // SwiftDataモデルコンテナの設定
        let schema = Schema([
            SwiftDataBook.self,
            SwiftDataUser.self,
            SwiftDataLoan.self,
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            // モデルコンテナを作成
            sharedModelContainer = try ModelContainer(
                for: schema, configurations: [modelConfiguration])
            
            // リポジトリファクトリを作成
            let modelContext = sharedModelContainer.mainContext
            repositoryFactory = SwiftDataRepositoryFactory(modelContext: modelContext)
            
            // 各モデルを作成してDI
            let bookRepository = repositoryFactory.makeBookRepository()
            let userRepository = repositoryFactory.makeUserRepository()
            let loanRepository = repositoryFactory.makeLoanRepository()
            
            bookModel = BookModel(repository: bookRepository)
            userModel = UserModel(repository: userRepository)
            lendingModel = LendingModel(
                repository: loanRepository,
                bookRepository: bookRepository,
                userRepository: userRepository
            )
            
        } catch {
            fatalError("モデルコンテナの初期化に失敗しました: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(bookModel: bookModel, userModel: userModel, lendingModel: lendingModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
