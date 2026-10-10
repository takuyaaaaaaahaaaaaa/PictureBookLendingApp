import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics

/// Info.plistで自動収集を停止したうえで、明示同意後のみFirebaseを構成する。
@MainActor
final class FirebaseTelemetryRuntime: TelemetryRuntime {
    func configure() -> Bool {
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil
        else {
            return false
        }
        // SDKの永続trueはInfo.plistのfalseより優先される。必ずconfigureより先に停止する。
        // Firebase 12.18.0では停止と初期化が同じserial queueへこの順で投入される。
        // 固定版の根拠・SDK更新時の再確認事項はdocs/TELEMETRY_CONSENT.mdを参照。
        Analytics.setAnalyticsCollectionEnabled(false)
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        // trueにはしない。delete/enableの競合と次回起動時の自動送信を避ける。
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        return true
    }

    func setAnalyticsEnabled(_ enabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }
    func resetAnalyticsData() { Analytics.resetAnalyticsData() }
    func sendUnsentReports() { Crashlytics.crashlytics().sendUnsentReports() }
}
