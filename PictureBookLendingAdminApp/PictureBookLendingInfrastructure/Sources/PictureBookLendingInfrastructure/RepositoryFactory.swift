import PictureBookLendingDomain
import SwiftData

/// リポジトリファクトリプロトコル
///
/// リポジトリのインスタンスを生成するためのファクトリのインターフェース
@MainActor
public protocol RepositoryFactory {
    /// 絵本リポジトリを生成
    /// - Returns: BookRepositoryProtocolのインスタンス
    func makeBookRepository() -> BookRepositoryProtocol
    
    /// 利用者リポジトリを生成
    func makeUserRepository() -> UserRepositoryProtocol
    
    /// 貸出リポジトリを生成
    func makeLoanRepository() -> LoanRepositoryProtocol
    
    /// クラス（組）リポジトリを生成
    func makeClassGroupRepository() -> ClassGroupRepositoryProtocol
    
    /// 貸出設定リポジトリを生成
    func makeLoanSettingsRepository() -> LoanSettingsRepositoryProtocol
    
    /// 書籍検索ゲートウェイを生成
    func makeBookSearchGateway() -> BookSearchGatewayProtocol
}

/// SwiftData用リポジトリファクトリ実装
///
/// SwiftDataを使用してリポジトリのインスタンスを生成するファクトリ
/// シングルトンパターンを採用し、アプリケーション全体で共有されるModelContainerを管理
public final class SwiftDataRepositoryFactory: RepositoryFactory, @unchecked Sendable {
    /// シングルトンインスタンス
    @MainActor
    public static let shared = SwiftDataRepositoryFactory()
    
    /// 共有ModelContainer
    public let modelContainer: ModelContainer
    
    /// プライベートイニシャライザ（シングルトンのため）
    private init() {
        // SwiftDataモデルコンテナの設定
        let schema = Schema([
            SwiftDataBook.self,
            SwiftDataUser.self,
            SwiftDataLoan.self,
            SwiftDataClassGroup.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("ModelContainerの初期化に失敗しました: \(error)")
        }
    }
    
    /// テスト用のModelContainerを作成
    ///
    /// - Parameter isStoredInMemoryOnly: メモリ上のみにデータを保存するかどうか（デフォルト: true）
    /// - Returns: テスト用ModelContainer
    public static func makeTestModelContainer(isStoredInMemoryOnly: Bool = true) -> ModelContainer {
        let schema = Schema([
            SwiftDataBook.self,
            SwiftDataUser.self,
            SwiftDataLoan.self,
            SwiftDataClassGroup.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("テスト用ModelContainerの初期化に失敗しました: \(error)")
        }
    }
    
    /// 絵本リポジトリのインスタンスを生成
    ///
    /// - Returns: BookRepositoryProtocolのインスタンス
    public func makeBookRepository() -> BookRepositoryProtocol {
        SwiftDataBookRepository(modelContext: modelContainer.mainContext)
    }
    
    /// 利用者リポジトリのインスタンスを生成
    ///
    /// - Returns: UserRepositoryProtocolのインスタンス
    public func makeUserRepository() -> UserRepositoryProtocol {
        SwiftDataUserRepository(modelContext: modelContainer.mainContext)
    }
    
    /// 貸出リポジトリのインスタンスを生成
    ///
    /// - Returns: LoanRepositoryProtocolのインスタンス
    public func makeLoanRepository() -> LoanRepositoryProtocol {
        SwiftDataLoanRepository(modelContext: modelContainer.mainContext)
    }
    
    /// クラス（組）リポジトリのインスタンスを生成
    ///
    /// - Returns: ClassGroupRepositoryProtocolのインスタンス
    public func makeClassGroupRepository() -> ClassGroupRepositoryProtocol {
        SwiftDataClassGroupRepository(modelContext: modelContainer.mainContext)
    }
    
    /// 貸出設定リポジトリのインスタンスを生成
    ///
    /// - Returns: LoanSettingsRepositoryProtocolのインスタンス
    public func makeLoanSettingsRepository() -> LoanSettingsRepositoryProtocol {
        UserDefaultsLoanSettingsRepository()
    }
    
    /// 書籍検索ゲートウェイのインスタンスを生成
    ///
    /// - Returns: BookSearchGatewayProtocolのインスタンス
    public func makeBookSearchGateway() -> BookSearchGatewayProtocol {
        GoogleBookSearchGateway()
    }
}
