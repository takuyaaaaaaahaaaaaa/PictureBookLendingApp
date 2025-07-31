import PictureBookLendingDomain
import SwiftData

/// リポジトリファクトリプロトコル
///
/// リポジトリのインスタンスを生成するためのファクトリのインターフェース
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
    
    /// 書籍メタデータゲートウェイを生成
    func makeBookMetadataGateway() -> BookMetadataGatewayProtocol
}

/// SwiftData用リポジトリファクトリ実装
///
/// SwiftDataを使用してリポジトリのインスタンスを生成するファクトリ
public class SwiftDataRepositoryFactory: RepositoryFactory {
    private let modelContext: ModelContext
    
    /// イニシャライザ
    ///
    /// - Parameter modelContext: SwiftData用のモデルコンテキスト
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 絵本リポジトリのインスタンスを生成
    ///
    /// - Returns: BookRepositoryProtocolのインスタンス
    public func makeBookRepository() -> BookRepositoryProtocol {
        SwiftDataBookRepository(modelContext: modelContext)
    }
    
    /// 利用者リポジトリのインスタンスを生成
    ///
    /// - Returns: UserRepositoryProtocolのインスタンス
    public func makeUserRepository() -> UserRepositoryProtocol {
        SwiftDataUserRepository(modelContext: modelContext)
    }
    
    /// 貸出リポジトリのインスタンスを生成
    ///
    /// - Returns: LoanRepositoryProtocolのインスタンス
    public func makeLoanRepository() -> LoanRepositoryProtocol {
        SwiftDataLoanRepository(modelContext: modelContext)
    }
    
    /// クラス（組）リポジトリのインスタンスを生成
    ///
    /// - Returns: ClassGroupRepositoryProtocolのインスタンス
    public func makeClassGroupRepository() -> ClassGroupRepositoryProtocol {
        SwiftDataClassGroupRepository(modelContext: modelContext)
    }
    
    /// 貸出設定リポジトリのインスタンスを生成
    ///
    /// - Returns: LoanSettingsRepositoryProtocolのインスタンス
    public func makeLoanSettingsRepository() -> LoanSettingsRepositoryProtocol {
        UserDefaultsLoanSettingsRepository()
    }
    
    /// 書籍メタデータゲートウェイのインスタンスを生成
    ///
    /// - Returns: BookMetadataGatewayProtocolのインスタンス
    public func makeBookMetadataGateway() -> BookMetadataGatewayProtocol {
        BookMetadataGateway()
    }
}
