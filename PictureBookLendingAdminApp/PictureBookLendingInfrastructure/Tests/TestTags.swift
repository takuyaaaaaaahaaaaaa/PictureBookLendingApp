import Foundation
import Testing

/// テストタグの定義
extension Tag {
    /// 統合テスト（外部APIを使用するテスト）
    /// CI/CD環境では除外される
    @Tag static var integrationTest: Self
}

/// テスト実行条件の定義
extension Trait where Self == ConditionTrait {
    /// ライブAPI（Google Books API）を使用するテストの実行条件
    /// レート制限（429）による不安定さを避けるため、
    /// 環境変数 RUN_LIVE_API_TESTS=1 を設定した場合のみ実行される
    static var liveAPITest: ConditionTrait {
        .enabled(if: ProcessInfo.processInfo.environment["RUN_LIVE_API_TESTS"] == "1")
    }
    
    /// 楽天ブックスAPIのライブテストを実行する条件
    /// RUN_LIVE_API_TESTS=1 かつ RAKUTEN_APPLICATION_ID が設定されている場合のみ実行される
    static var rakutenLiveAPITest: ConditionTrait {
        .enabled(
            if: ProcessInfo.processInfo.environment["RUN_LIVE_API_TESTS"] == "1"
                && !(ProcessInfo.processInfo.environment["RAKUTEN_APPLICATION_ID"] ?? "").isEmpty)
    }
}

/// テスト用のヘルパー
extension ProcessInfo {
    /// 環境変数から楽天アプリIDを取得する（未設定時は空文字列）
    var rakutenApplicationId: String {
        environment["RAKUTEN_APPLICATION_ID"] ?? ""
    }
}
