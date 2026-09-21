import FirebaseAnalytics

/// `AnalyticsParamValue` をFirebase Analytics（GA4）に渡せるパラメータ辞書へ変換する
///
/// `Analytics.logEvent(_:parameters:)` はSDK呼び出しのためテストで直接検証できない。
/// 変換ロジックだけをこの関数に切り出し、単体テスト可能にする。
enum FirebaseAnalyticsParameterMapper {
    /// GA4のイベントパラメータとして送信できる形（`[String: Any]`）へ変換する
    static func makeParameters(from params: [String: AnalyticsParamValue]) -> [String: Any] {
        params.mapValues { value in
            switch value {
            case .string(let string): string
            case .int(let int): int
            case .bool(let bool): bool
            }
        }
    }
}

/// Firebase Analyticsへ記録する実装
///
/// `Analytics.logEvent(name:parameters:)` への薄いラッパー。
/// イベントの意味・送信タイミングの判断はApp層／`AnalyticsService`の呼び出し側が持つため、
/// ここではパラメータの型変換以外のロジックを持たない（docs/ANALYTICS_DESIGN.md §5）。
public struct FirebaseAnalyticsService: AnalyticsService {
    public init() {}
    
    public func track(name: String, params: [String: AnalyticsParamValue]) {
        Analytics.logEvent(
            name, parameters: FirebaseAnalyticsParameterMapper.makeParameters(from: params))
    }
}
