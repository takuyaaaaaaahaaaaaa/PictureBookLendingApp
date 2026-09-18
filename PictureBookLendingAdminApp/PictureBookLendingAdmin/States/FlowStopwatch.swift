import Foundation

/// フロー所要時間の計測（貸出シート表示から完了まで等）
///
/// 計測中にアプリがバックグラウンドへ行った場合、その滞在時間は所要時間として
/// 意味を持たないため計測ごと無効化する（docs/ANALYTICS_DESIGN.md §4 の制約）。
/// 無効化後は`elapsedMs(at:)`がnilを返し、イベントからは所要時間のキーごと落ちる。
struct FlowStopwatch: Equatable {
    /// ミリ秒換算の係数
    private static let millisecondsPerSecond: Double = 1000
    
    /// 計測開始時刻
    private let startedAt: Date
    /// 計測が有効かどうか（バックグラウンド滞在で失われる）
    private var isValid = true
    
    init(startedAt: Date = Date()) {
        self.startedAt = startedAt
    }
    
    /// 計測を無効化する（バックグラウンドへ行ったとき）
    mutating func invalidate() {
        isValid = false
    }
    
    /// 開始からの経過ミリ秒（無効化済みならnil）
    func elapsedMs(at now: Date = Date()) -> Int? {
        guard isValid else { return nil }
        return Int(now.timeIntervalSince(startedAt) * Self.millisecondsPerSecond)
    }
}
