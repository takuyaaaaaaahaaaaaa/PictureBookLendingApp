import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import SwiftData
import SwiftUI
import TipKit

@main
struct PictureBookLendingAdminApp: App {
    
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
    
    /// バックアップモデル
    @State private var backupModel: BackupModel
    
    /// 設定から後で撤回できる。未選択は送信しない。
    @State private var privacy: TelemetryPrivacyController
    
    init() {
        try? Tips.configure()

        #if DEBUG
            let privacy = TelemetryPrivacyController(
                analyticsDestination: ConsoleAnalyticsService())
        #else
            let privacy = TelemetryPrivacyController(
                analyticsDestination: FirebaseAnalyticsService())
        #endif
        _privacy = State(initialValue: privacy)
        privacy.start()
        
        // シングルトンのRepositoryFactoryを使用
        let repositoryFactory = SwiftDataRepositoryFactory.shared
        
        // 各モデルを作成してDI
        let bookRepository = repositoryFactory.makeBookRepository()
        let userRepository = repositoryFactory.makeUserRepository()
        let loanRepository = repositoryFactory.makeLoanRepository()
        let classGroupRepository = repositoryFactory.makeClassGroupRepository()
        let loanSettingsRepository = repositoryFactory.makeLoanSettingsRepository()
        let imageStorageRepository = repositoryFactory.makeImageStorageRepository()
        
        // @StateのwrappedValueを使用して初期化
        _bookModel = State(wrappedValue: BookModel(repository: bookRepository, imageStorageRepository: imageStorageRepository))
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
        _backupModel = State(
            wrappedValue: BackupModel(
                bookRepository: bookRepository,
                userRepository: userRepository,
                classGroupRepository: classGroupRepository,
                loanRepository: loanRepository,
                loanSettingsRepository: loanSettingsRepository,
                imageStorageRepository: imageStorageRepository
            ))
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(bookModel)
                .environment(userModel)
                .environment(loanModel)
                .environment(classGroupModel)
                .environment(loanSettingsModel)
                .environment(backupModel)
                .environment(privacy)
                .environment(\.analytics, privacy.analytics)
        }
        .modelContainer(SwiftDataRepositoryFactory.shared.modelContainer)
    }
}
