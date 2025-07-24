/// 貸出設定リポジトリプロトコル
///
/// 貸出設定の永続化に関する操作を定義します。
public protocol LoanSettingsRepositoryProtocol: Sendable {
    /// 貸出設定を取得する
    /// - Returns: 貸出設定。初回起動時などでデータがない場合はデフォルト設定を返す
    func fetch() -> LoanSettings
    
    /// 貸出設定を保存する
    /// - Parameter settings: 保存する貸出設定
    /// - Throws: 保存に失敗した場合にエラーを投げる
    func save(_ settings: LoanSettings) throws
}
