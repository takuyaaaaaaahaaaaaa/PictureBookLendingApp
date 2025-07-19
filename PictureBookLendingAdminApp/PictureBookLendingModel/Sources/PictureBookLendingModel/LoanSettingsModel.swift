import Foundation
import Observation
import PictureBookLendingDomain

/// 貸出設定管理モデル
///
/// 貸出設定の取得・更新を管理するモデルクラスです。
@Observable
public class LoanSettingsModel {
    /// 現在の貸出設定
    public private(set) var settings: LoanSettings
    
    /// 貸出設定リポジトリ
    private let repository: LoanSettingsRepositoryProtocol
    
    /// イニシャライザ
    /// - Parameter repository: 貸出設定リポジトリ
    public init(repository: LoanSettingsRepositoryProtocol) {
        self.repository = repository
        self.settings = repository.fetch()
    }
    
    /// 貸出設定を更新する
    /// - Parameter newSettings: 新しい貸出設定
    /// - Throws: 保存に失敗した場合にエラーを投げる
    public func updateSettings(_ newSettings: LoanSettings) throws {
        guard newSettings.isValid() else {
            throw LoanSettingsError.invalidSettings
        }
        
        try repository.save(newSettings)
        settings = newSettings
    }
    
    /// 設定を初期値にリセットする
    /// - Throws: 保存に失敗した場合にエラーを投げる
    public func resetToDefault() throws {
        try updateSettings(.default)
    }
}

/// 貸出設定に関するエラー
public enum LoanSettingsError: Error, Equatable, LocalizedError {
    /// 無効な設定値
    case invalidSettings
    
    public var errorDescription: String? {
        switch self {
        case .invalidSettings:
            return "無効な設定値です"
        }
    }
}
