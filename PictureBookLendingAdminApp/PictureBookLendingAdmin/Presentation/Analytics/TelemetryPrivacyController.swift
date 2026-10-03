import Foundation
import Observation
import PictureBookLendingInfrastructure
import os

/// 未選択を同意へ変換しない。falseのUI表示でも未選択と拒否は区別する。
enum TelemetryConsent: String, Codable {
    case unspecified
    case allowed
    case denied
}

@MainActor
protocol TelemetryRuntime: AnyObject {
    /// Analyticsを停止してからFirebaseを構成する。
    func configure() -> Bool
    func setAnalyticsEnabled(_ enabled: Bool)
    func resetAnalyticsData()
    func sendUnsentReports()
}

/// 非同期イベントが同意前/撤回後にSDKへ流れないよう、同意判定と転送を直列化する。
final class ConsentGatedAnalyticsService: AnalyticsService {
    private let enabled = OSAllocatedUnfairLock(initialState: false)
    private let destination: any AnalyticsService
    
    init(destination: any AnalyticsService) { self.destination = destination }
    func setEnabled(_ value: Bool) { enabled.withLock { $0 = value } }
    func track(name: String, params: [String: AnalyticsParamValue]) {
        enabled.withLock { allowed in
            guard allowed else { return }
            destination.track(name: name, params: params)
        }
    }
}

@Observable
@MainActor
final class TelemetryPrivacyController {
    private struct Record: Codable {
        var version = 1
        var analytics = TelemetryConsent.unspecified
        var diagnostics = TelemetryConsent.unspecified
    }
    
    private var record: Record
    private let store: any TelemetryConsentStore
    private let runtime: any TelemetryRuntime
    private var started = false
    private var hasRequestedDiagnosticsSend = false
    private var runtimeStarted = false
    private var resetAnalyticsOnStart: Bool
    private(set) var isRuntimeAvailable = false
    private(set) var persistenceError: String?
    let analytics: ConsentGatedAnalyticsService
    
    var analyticsConsent: TelemetryConsent { record.analytics }
    var diagnosticsConsent: TelemetryConsent { record.diagnostics }
    var needsInitialConsent: Bool {
        record.analytics == .unspecified && record.diagnostics == .unspecified
    }
    
    init(
        store: (any TelemetryConsentStore)? = nil,
        runtime: (any TelemetryRuntime)? = nil,
        analyticsDestination: any AnalyticsService = FirebaseAnalyticsService()
    ) {
        let store = store ?? FileTelemetryConsentStore()
        self.store = store
        self.runtime = runtime ?? FirebaseTelemetryRuntime()
        let decoded = (try? store.load()).flatMap {
            try? JSONDecoder().decode(Record.self, from: $0)
        }
        let restored: Record
        if let decoded, decoded.version == 1 { restored = decoded } else { restored = Record() }
        record = restored
        resetAnalyticsOnStart = restored.analytics != .allowed
        analytics = ConsentGatedAnalyticsService(destination: analyticsDestination)
    }
    
    func dismissPersistenceError() { persistenceError = nil }
    
    func start() {
        guard !started else { return }
        started = true
        activateIfNeeded()
    }
    
    /// 起動時の選択は両項目を一度に保存し、成功後だけ送信を有効にする。
    func completeInitialConsent(allowed: Bool) {
        guard needsInitialConsent else { return }
        guard
            updateRecord({
                $0.analytics = allowed ? .allowed : .denied
                $0.diagnostics = allowed ? .allowed : .denied
            })
        else { return }
        activateIfNeeded()
    }
    
    func setAnalyticsConsent(_ allowed: Bool) {
        analytics.setEnabled(false)
        if !allowed && isRuntimeAvailable { runtime.setAnalyticsEnabled(false) }
        guard updateRecord({ $0.analytics = allowed ? .allowed : .denied }) else { return }
        if isRuntimeAvailable {
            runtime.setAnalyticsEnabled(allowed)
            if !allowed { runtime.resetAnalyticsData() }
            analytics.setEnabled(allowed)
        } else {
            resetAnalyticsOnStart = true
            activateIfNeeded()
        }
    }
    
    func setDiagnosticsConsent(_ allowed: Bool) {
        guard updateRecord({ $0.diagnostics = allowed ? .allowed : .denied }) else { return }
        activateIfNeeded()
        requestDiagnosticsIfAllowed()
    }
    
    private func activateIfNeeded() {
        guard started, !runtimeStarted,
            record.analytics == .allowed || record.diagnostics == .allowed
        else { return }
        runtimeStarted = true
        guard runtime.configure() else { return }
        isRuntimeAvailable = true
        if resetAnalyticsOnStart { runtime.resetAnalyticsData() }
        runtime.setAnalyticsEnabled(record.analytics == .allowed)
        analytics.setEnabled(record.analytics == .allowed)
        requestDiagnosticsIfAllowed()
    }
    
    private func requestDiagnosticsIfAllowed() {
        guard isRuntimeAvailable, record.diagnostics == .allowed,
            !hasRequestedDiagnosticsSend
        else { return }
        // 保存済み全件の送信への同意。SDKの自動収集は常にoffのまま、起動ごとに一度要求。
        // check=falseは全キューが空という保証ではないため、送信条件には使わない。
        hasRequestedDiagnosticsSend = true
        runtime.sendUnsentReports()
    }
    
    @discardableResult
    private func updateRecord(_ update: (inout Record) -> Void) -> Bool {
        var candidate = record
        update(&candidate)
        do {
            try store.save(JSONEncoder().encode(candidate))
            record = candidate
            persistenceError = nil
            return true
        } catch {
            analytics.setEnabled(false)
            if isRuntimeAvailable {
                runtime.setAnalyticsEnabled(false)
                runtime.resetAnalyticsData()
            }
            persistenceError =
                "変更を保存できませんでした。利用状況の収集はこの起動中停止しましたが、設定を保存できたか確認できません。診断の送信開始済み情報は取り消せません。再起動前に、もう一度変更してください。"
            return false
        }
    }
}
