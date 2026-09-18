import os

/// アナリティクスイベントのパラメータ値
///
/// 値の形を所要時間・件数・列挙値に限定する（docs/ANALYTICS_DESIGN.md 大原則2）。
/// ただし`.string`には任意の文字列が入るため、型だけでは識別子の混入は防げない。
/// 混入を防いでいるのは「記録の唯一の入口をApp層の`AnalyticsEvent`にし、
/// そこに識別子を受け取るケースを作らない」という規律のほう。
public enum AnalyticsParamValue: Equatable, Sendable, CustomStringConvertible {
    /// 列挙値（`find_method: shelf` 等のraw value）
    case string(String)
    /// 件数・所要時間
    case int(Int)
    /// 有無の判定
    case bool(Bool)
    
    public var description: String {
        switch self {
        case .string(let value): value
        case .int(let value): String(value)
        case .bool(let value): value ? "true" : "false"
        }
    }
}

/// 利用ログの記録先を抽象化するプロトコル
///
/// イベントの意味を知らない「記録して送る」だけの配管。
/// 画面語彙（どんなイベントがあるか）はApp層の`AnalyticsEvent`が持つ
/// （docs/ANALYTICS_DESIGN.md §5）。
public protocol AnalyticsService: Sendable {
    /// イベントを記録する
    /// - Parameters:
    ///   - name: イベント名（GA4流のsnake_case）
    ///   - params: イベントのプロパティ
    func track(name: String, params: [String: AnalyticsParamValue])
}

/// DEBUGビルド用の記録先（os.Loggerへ出力するだけで送信はしない）
///
/// Phase Aで実機の操作を眺め、イベント設計の妥当性を確かめるために使う。
public struct ConsoleAnalyticsService: AnalyticsService {
    private let logger = Logger(subsystem: "com.picturebooklending", category: "Analytics")
    
    public init() {}
    
    public func track(name: String, params: [String: AnalyticsParamValue]) {
        // 辞書の列挙順は不定のため、キー順に並べて毎回同じ並びで出力する
        let formattedParams =
            params
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.description)" }
            .joined(separator: " ")
        let message = formattedParams.isEmpty ? name : "\(name) \(formattedParams)"
        // debugではなくinfo：debugレベルはデフォルトで永続化されず、
        // 実機の操作を後からConsole.appで眺めるという Phase A の目的を果たせないため
        logger.info("📊 \(message, privacy: .public)")
    }
}

/// 何もしない記録先（Release・Previewの既定値）
public struct NoopAnalyticsService: AnalyticsService {
    public init() {}
    
    public func track(name: String, params: [String: AnalyticsParamValue]) {}
}
