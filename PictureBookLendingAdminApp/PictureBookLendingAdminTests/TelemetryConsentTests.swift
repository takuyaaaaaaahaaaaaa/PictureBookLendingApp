import Foundation
import PictureBookLendingInfrastructure
import Testing
import os

@testable import PictureBookLendingAdmin

@Suite("Telemetry consent", .serialized)
@MainActor
struct TelemetryConsentTests {
    private func makeStore() -> MemoryConsentStore { MemoryConsentStore() }
    
    @Test("新規・既存インストールに同意を補完しない")
    func unspecifiedDoesNotConfigure() {
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: makeStore(), runtime: runtime)
        controller.start()
        #expect(controller.analyticsConsent == .unspecified)
        #expect(controller.diagnosticsConsent == .unspecified)
        #expect(controller.needsInitialConsent)
        #expect(runtime.calls.isEmpty)
    }
    
    @Test("起動時の同意/拒否は両項目を一度に保存し、次回起動で再表示しない", arguments: [true, false])
    func initialChoicePersistsBothConsents(allowed: Bool) {
        let store = makeStore()
        let runtime = TelemetryRuntimeSpy()
        let recorder = AnalyticsRecorder()
        let controller = TelemetryPrivacyController(
            store: store, runtime: runtime, analyticsDestination: recorder)
        controller.start()
        controller.analytics.track(name: "beforeChoice", params: [:])
        #expect(runtime.calls.isEmpty)
        #expect(recorder.names.withLock { $0 }.isEmpty)
        
        controller.completeInitialConsent(allowed: allowed)
        #expect(store.saveCount == 1)
        #expect(controller.analyticsConsent == (allowed ? .allowed : .denied))
        #expect(controller.diagnosticsConsent == (allowed ? .allowed : .denied))
        #expect(!controller.needsInitialConsent)
        #expect(
            runtime.calls
                == (allowed ? ["configure", "resetAnalytics", "analytics:true", "send"] : []))
        controller.analytics.track(name: "afterChoice", params: [:])
        #expect(recorder.names.withLock { $0 } == (allowed ? ["afterChoice"] : []))
        
        let nextRuntime = TelemetryRuntimeSpy()
        let next = TelemetryPrivacyController(store: store, runtime: nextRuntime)
        next.start()
        #expect(!next.needsInitialConsent)
        #expect(next.analyticsConsent == controller.analyticsConsent)
        #expect(next.diagnosticsConsent == controller.diagnosticsConsent)
        #expect(nextRuntime.calls == (allowed ? ["configure", "analytics:true", "send"] : []))
    }
    
    @Test("起動時の保存失敗では未選択を維持し、送信せず再試行できる", arguments: [true, false])
    func initialChoiceSaveFailureCanRetry(allowed: Bool) {
        let store = makeStore()
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: store, runtime: runtime)
        controller.start()
        store.failsSave = true
        controller.completeInitialConsent(allowed: allowed)
        #expect(controller.needsInitialConsent)
        #expect(controller.analyticsConsent == .unspecified)
        #expect(controller.diagnosticsConsent == .unspecified)
        #expect(controller.persistenceError != nil)
        #expect(runtime.calls.isEmpty)
        
        controller.dismissPersistenceError()
        #expect(controller.needsInitialConsent)
        store.failsSave = false
        controller.completeInitialConsent(allowed: allowed)
        #expect(!controller.needsInitialConsent)
        #expect(controller.persistenceError == nil)
        #expect(runtime.calls.filter { $0 == "send" }.count == (allowed ? 1 : 0))
    }
    
    @Test("起動時のファイル置換後の保存失敗でも送信せず、拒否で再試行できる")
    func initialChoicePostWriteFailureDoesNotSend() {
        let store = makeStore()
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: store, runtime: runtime)
        controller.start()
        store.failsAfterWrite = true
        controller.completeInitialConsent(allowed: true)
        #expect(controller.needsInitialConsent)
        #expect(controller.persistenceError != nil)
        #expect(runtime.calls.isEmpty)
        store.failsAfterWrite = false
        controller.completeInitialConsent(allowed: false)
        let next = TelemetryPrivacyController(store: store, runtime: TelemetryRuntimeSpy())
        #expect(next.analyticsConsent == .denied)
        #expect(next.diagnosticsConsent == .denied)
        #expect(!next.needsInitialConsent)
    }
    
    @Test("送信サービスがなくても起動時の同意を保存して利用を開始できる")
    func initialChoiceWithoutFirebaseConfiguration() {
        let store = makeStore()
        let runtime = TelemetryRuntimeSpy()
        runtime.canConfigure = false
        let controller = TelemetryPrivacyController(store: store, runtime: runtime)
        controller.start()
        controller.completeInitialConsent(allowed: true)
        #expect(!controller.needsInitialConsent)
        #expect(!controller.isRuntimeAvailable)
        #expect(runtime.calls == ["configure"])
        #expect(
            !TelemetryPrivacyController(store: store, runtime: TelemetryRuntimeSpy())
                .needsInitialConsent)
    }
    
    @Test("一部でも設定済みなら再表示せず、古い起動画面の操作で上書きしない", arguments: [true, false])
    func initialChoicePreservesExistingIndividualChoices(allowed: Bool) {
        for selectsAnalytics in [true, false] {
            let store = makeStore()
            let existing = TelemetryPrivacyController(store: store, runtime: TelemetryRuntimeSpy())
            if selectsAnalytics {
                existing.setAnalyticsConsent(allowed)
            } else {
                existing.setDiagnosticsConsent(allowed)
            }
            let controller = TelemetryPrivacyController(
                store: store, runtime: TelemetryRuntimeSpy())
            let original = store.data
            #expect(!controller.needsInitialConsent)
            controller.completeInitialConsent(allowed: !allowed)
            #expect(store.data == original)
            #expect(store.saveCount == 1)
        }
    }
    
    @Test("起動時の選択後に重複操作しても同意を書き換えず、送信要求を重複しない")
    func initialChoiceIsNotRepeated() {
        let store = makeStore()
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: store, runtime: runtime)
        controller.start()
        controller.completeInitialConsent(allowed: true)
        controller.completeInitialConsent(allowed: false)
        controller.start()
        #expect(store.saveCount == 1)
        #expect(controller.analyticsConsent == .allowed)
        #expect(controller.diagnosticsConsent == .allowed)
        #expect(runtime.calls.filter { $0 == "send" }.count == 1)
    }
    
    @Test("初回analytics同意後だけSDKを構成し、撤回で停止・ローカルリセット")
    func analyticsConsentAndWithdrawal() {
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: makeStore(), runtime: runtime)
        controller.start()
        controller.setAnalyticsConsent(true)
        #expect(runtime.calls.prefix(2) == ["configure", "resetAnalytics"])
        #expect(runtime.calls.contains("analytics:true"))
        controller.setAnalyticsConsent(false)
        #expect(Array(runtime.calls.suffix(2)) == ["analytics:false", "resetAnalytics"])
        #expect(controller.analyticsConsent == .denied)
    }
    
    @Test("診断だけの許可はAnalyticsを有効にせず、保存済み全件を一度要求する")
    func diagnosticsOnlyAutomaticallySendsOnce() {
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: makeStore(), runtime: runtime)
        controller.start()
        controller.setDiagnosticsConsent(true)
        controller.start()
        controller.setDiagnosticsConsent(true)
        #expect(runtime.calls.filter { $0 == "send" }.count == 1)
        #expect(!runtime.calls.contains("analytics:true"))
        #expect(controller.analyticsConsent == .unspecified)
    }
    
    @Test("診断許可の次回起動では自動送信し、拒否後の起動では送信しない")
    func diagnosticsConsentControlsNextLaunch() {
        let store = makeStore()
        let initial = TelemetryPrivacyController(store: store, runtime: TelemetryRuntimeSpy())
        initial.start()
        initial.setDiagnosticsConsent(true)
        let second = TelemetryRuntimeSpy()
        let restarted = TelemetryPrivacyController(store: store, runtime: second)
        restarted.start()
        #expect(second.calls.filter { $0 == "send" }.count == 1)
        restarted.setDiagnosticsConsent(false)
        #expect(second.calls.filter { $0 == "send" }.count == 1)
        let third = TelemetryRuntimeSpy()
        let withdrawn = TelemetryPrivacyController(store: store, runtime: third)
        withdrawn.start()
        #expect(third.calls.isEmpty)
    }
    
    @Test("診断の撤回後に再許可しても同一起動中の送信要求を重複しない")
    func diagnosticsReconsentDoesNotDuplicateRequest() {
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: makeStore(), runtime: runtime)
        controller.start()
        controller.setDiagnosticsConsent(true)
        controller.setDiagnosticsConsent(false)
        controller.setDiagnosticsConsent(true)
        #expect(runtime.calls.filter { $0 == "send" }.count == 1)
    }
    
    @Test("診断許可の保存失敗では送信せず、撤回保存失敗は再試行を求める")
    func diagnosticsPersistenceFailureDoesNotGrantConsent() {
        let store = makeStore()
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: store, runtime: runtime)
        controller.start()
        store.failsSave = true
        controller.setDiagnosticsConsent(true)
        #expect(controller.diagnosticsConsent == .unspecified)
        #expect(runtime.calls.isEmpty)
        store.failsSave = false
        controller.setDiagnosticsConsent(true)
        store.failsSave = true
        controller.setDiagnosticsConsent(false)
        #expect(controller.diagnosticsConsent == .allowed)
        #expect(controller.persistenceError != nil)
        #expect(runtime.calls.filter { $0 == "send" }.count == 1)
        store.failsSave = false
        controller.setDiagnosticsConsent(false)
        let next = TelemetryRuntimeSpy()
        TelemetryPrivacyController(store: store, runtime: next).start()
        #expect(next.calls.isEmpty)
    }
    
    @Test("SDK設定なしでも貸出アプリは動き、送信を試みない")
    func missingConfigurationFailsClosed() {
        let runtime = TelemetryRuntimeSpy()
        runtime.canConfigure = false
        let controller = TelemetryPrivacyController(store: makeStore(), runtime: runtime)
        controller.start()
        controller.setAnalyticsConsent(true)
        #expect(runtime.calls == ["configure"])
        #expect(!controller.isRuntimeAvailable)
    }
    
    @Test("同意撤回後の再起動も未送信を維持する")
    func withdrawnConsentSurvivesRestart() {
        let store = makeStore()
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: store, runtime: runtime)
        controller.start()
        controller.setAnalyticsConsent(true)
        controller.setDiagnosticsConsent(true)
        controller.setAnalyticsConsent(false)
        controller.setDiagnosticsConsent(false)
        let nextRuntime = TelemetryRuntimeSpy()
        let next = TelemetryPrivacyController(store: store, runtime: nextRuntime)
        next.start()
        #expect(next.analyticsConsent == .denied)
        #expect(next.diagnosticsConsent == .denied)
        #expect(nextRuntime.calls.isEmpty)
    }
    
    @Test("Analyticsイベントは同意中だけ転送し、保留しない")
    func analyticsGateDoesNotQueueEvents() {
        let recorder = AnalyticsRecorder()
        let gate = ConsentGatedAnalyticsService(destination: recorder)
        gate.track(name: "before", params: [:])
        gate.setEnabled(true)
        gate.track(name: "allowed", params: [:])
        gate.setEnabled(false)
        gate.track(name: "after", params: [:])
        gate.setEnabled(true)
        #expect(recorder.names.withLock { $0 } == ["allowed"])
    }
    
    @Test("保存失敗は同意にしない・送信を開始しない")
    func writeFailureFailsClosed() {
        let store = makeStore()
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: store, runtime: runtime)
        controller.start()
        store.failsSave = true
        controller.setAnalyticsConsent(true)
        #expect(controller.analyticsConsent == .unspecified)
        #expect(controller.persistenceError != nil)
        #expect(runtime.calls.isEmpty)
    }
    
    @Test("撤回の保存失敗は当該起動の送信を停止し、再試行で拒否を保存する")
    func failedWithdrawalStopsCurrentSessionAndCanRetry() {
        let store = makeStore()
        let runtime = TelemetryRuntimeSpy()
        let recorder = AnalyticsRecorder()
        let controller = TelemetryPrivacyController(
            store: store, runtime: runtime, analyticsDestination: recorder)
        controller.start()
        controller.setAnalyticsConsent(true)
        controller.analytics.track(name: "allowed", params: [:])
        store.failsSave = true
        controller.setAnalyticsConsent(false)
        controller.analytics.track(name: "afterFailedWithdrawal", params: [:])
        #expect(Array(runtime.calls.suffix(2)) == ["analytics:false", "resetAnalytics"])
        #expect(recorder.names.withLock { $0 } == ["allowed"])
        #expect(controller.persistenceError != nil)
        // 保存失敗を成功表示しない。拒否の永続化には再試行が必要。
        #expect(controller.analyticsConsent == .allowed)
        store.failsSave = false
        controller.setAnalyticsConsent(false)
        #expect(controller.persistenceError == nil)
        let restarted = TelemetryPrivacyController(store: store, runtime: TelemetryRuntimeSpy())
        #expect(restarted.analyticsConsent == .denied)
    }
    
    @Test("ファイル置換後の同期失敗も保存未確認として通知し、当該起動では送らない")
    func failureAfterReplacementDoesNotStartCollection() {
        let store = makeStore()
        let runtime = TelemetryRuntimeSpy()
        let controller = TelemetryPrivacyController(store: store, runtime: runtime)
        controller.start()
        store.failsAfterWrite = true
        controller.setAnalyticsConsent(true)
        #expect(controller.persistenceError?.contains("確認できません") == true)
        #expect(controller.analyticsConsent == .unspecified)
        #expect(runtime.calls.isEmpty)
        // atomic置換は済んでいる場合がある。画面は旧値の永続化を保証しない。
        let restored = TelemetryPrivacyController(store: store, runtime: TelemetryRuntimeSpy())
        #expect(restored.analyticsConsent == .allowed)
        store.failsAfterWrite = false
        controller.setAnalyticsConsent(false)
        #expect(controller.persistenceError == nil)
        #expect(
            TelemetryPrivacyController(store: store, runtime: TelemetryRuntimeSpy())
                .analyticsConsent == .denied)
    }
    
    @Test("ファイルを別ストアから開き直しても撤回が残る")
    func fileStorePersistsWithdrawal() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("consent.json")
        let controller = TelemetryPrivacyController(
            store: FileTelemetryConsentStore(url: url), runtime: TelemetryRuntimeSpy())
        controller.start()
        controller.setAnalyticsConsent(true)
        controller.setAnalyticsConsent(false)
        let restored = TelemetryPrivacyController(
            store: FileTelemetryConsentStore(url: url), runtime: TelemetryRuntimeSpy())
        #expect(restored.analyticsConsent == .denied)
    }
    
    @Test("未知バージョン/破損した永続データは未同意扱い")
    func invalidStoredConsentFailsClosed() {
        for data in [
            Data("broken".utf8),
            Data("{\"version\":999}".utf8),
            Data("{\"version\":999,\"analytics\":\"allowed\",\"diagnostics\":\"allowed\"}".utf8),
        ] {
            let store = makeStore()
            store.data = data
            let runtime = TelemetryRuntimeSpy()
            let controller = TelemetryPrivacyController(store: store, runtime: runtime)
            controller.start()
            #expect(controller.analyticsConsent == .unspecified)
            #expect(controller.diagnosticsConsent == .unspecified)
            #expect(runtime.calls.isEmpty)
        }
    }
}

@MainActor
private final class TelemetryRuntimeSpy: TelemetryRuntime {
    var calls: [String] = []
    var canConfigure = true
    func configure() -> Bool {
        calls.append("configure")
        return canConfigure
    }
    func setAnalyticsEnabled(_ enabled: Bool) { calls.append("analytics:\(enabled)") }
    func resetAnalyticsData() { calls.append("resetAnalytics") }
    func sendUnsentReports() { calls.append("send") }
}

private final class AnalyticsRecorder: AnalyticsService {
    let names = OSAllocatedUnfairLock(initialState: [String]())
    func track(name: String, params: [String: AnalyticsParamValue]) {
        names.withLock { $0.append(name) }
    }
}

@MainActor
private final class MemoryConsentStore: TelemetryConsentStore {
    var data: Data?
    var saveCount = 0
    var failsSave = false
    var failsAfterWrite = false
    func load() throws -> Data? { data }
    func save(_ data: Data) throws {
        saveCount += 1
        if failsSave { throw CocoaError(.fileWriteNoPermission) }
        self.data = data
        if failsAfterWrite { throw CocoaError(.fileWriteUnknown) }
    }
}
