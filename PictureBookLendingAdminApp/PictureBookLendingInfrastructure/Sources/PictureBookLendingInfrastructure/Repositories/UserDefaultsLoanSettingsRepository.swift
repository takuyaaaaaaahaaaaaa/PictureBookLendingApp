import Foundation
import PictureBookLendingDomain

/// UserDefaultsを使用した貸出設定リポジトリ実装
public final class UserDefaultsLoanSettingsRepository: LoanSettingsRepositoryProtocol,
    @unchecked
    Sendable
{
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private enum Keys {
        static let loanSettings = "PictureBookLending_LoanSettings"
    }
    
    /// イニシャライザ
    /// - Parameter userDefaults: 使用するUserDefaultsインスタンス（デフォルトは.standard）
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    /// 貸出設定を取得する
    /// - Returns: 貸出設定。初回起動時などでデータがない場合はデフォルト設定を返す
    public func fetch() -> LoanSettings {
        guard let data = userDefaults.data(forKey: Keys.loanSettings) else {
            return .default
        }
        
        do {
            return try decoder.decode(LoanSettings.self, from: data)
        } catch {
            // デコードに失敗した場合はデフォルト設定を返す
            return .default
        }
    }
    
    /// 貸出設定を保存する
    /// - Parameter settings: 保存する貸出設定
    /// - Throws: 保存に失敗した場合にエラーを投げる
    public func save(_ settings: LoanSettings) throws {
        let data = try encoder.encode(settings)
        userDefaults.set(data, forKey: Keys.loanSettings)
    }
}
