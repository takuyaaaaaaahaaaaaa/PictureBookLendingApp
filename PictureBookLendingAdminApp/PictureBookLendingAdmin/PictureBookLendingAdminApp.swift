import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import SwiftData
import SwiftUI

@main
struct PictureBookLendingAdminApp: App {
    /// アプリで使用するSwiftDataモデルコンテナ
    var sharedModelContainer: ModelContainer
    
    /// 絵本モデル
    @State private var bookModel: BookModel
    
    /// 利用者モデル
    @State private var userModel: UserModel
    
    /// 貸出モデル
    @State private var loanModel: LoanModel
    
    /// クラス（組）モデル
    @State private var classGroupModel: ClassGroupModel
    
    /// 貸出設定モデル
    @State private var loanSettingsModel: LoanSettingsModel
    
    init() {
        // SwiftDataモデルコンテナの設定
        let schema = Schema([
            SwiftDataBook.self,
            SwiftDataUser.self,
            SwiftDataLoan.self,
            SwiftDataClassGroup.self,
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            // モデルコンテナを作成
            sharedModelContainer = try ModelContainer(
                for: schema, configurations: [modelConfiguration])
            
            // リポジトリファクトリを作成
            let modelContext = sharedModelContainer.mainContext
            let repositoryFactory = SwiftDataRepositoryFactory(modelContext: modelContext)
            
            // 各モデルを作成してDI
            let bookRepository = repositoryFactory.makeBookRepository()
            let userRepository = repositoryFactory.makeUserRepository()
            let loanRepository = repositoryFactory.makeLoanRepository()
            let classGroupRepository = repositoryFactory.makeClassGroupRepository()
            let loanSettingsRepository = repositoryFactory.makeLoanSettingsRepository()
            
            // @StateのwrappedValueを使用して初期化
            _bookModel = State(wrappedValue: BookModel(repository: bookRepository))
            _userModel = State(wrappedValue: UserModel(repository: userRepository))
            _loanModel = State(
                wrappedValue: LoanModel(
                    repository: loanRepository,
                    bookRepository: bookRepository,
                    userRepository: userRepository,
                    loanSettingsRepository: loanSettingsRepository
                ))
            _classGroupModel = State(
                wrappedValue: ClassGroupModel(repository: classGroupRepository))
            _loanSettingsModel = State(
                wrappedValue: LoanSettingsModel(repository: loanSettingsRepository))
            
        } catch {
            fatalError("モデルコンテナの初期化に失敗しました: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(bookModel)
                .environment(userModel)
                .environment(loanModel)
                .environment(classGroupModel)
                .environment(loanSettingsModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
