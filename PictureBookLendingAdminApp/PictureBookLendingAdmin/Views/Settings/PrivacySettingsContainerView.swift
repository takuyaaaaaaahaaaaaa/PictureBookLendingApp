import PictureBookLendingUI
import SwiftUI

struct PrivacySettingsContainerView: View {
    @Environment(TelemetryPrivacyController.self) private var privacy

    /// GitHub Pagesの設定と公開ページの200応答を2026-10-02に確認。
    static let policyURL = URL(
        string: "https://takuyaaaaaaahaaaaaa.github.io/PictureBookLendingApp/privacy-policy")!

    var body: some View {
        PrivacySettingsView(
            analyticsEnabled: Binding(
                get: { privacy.analyticsConsent == .allowed }, set: privacy.setAnalyticsConsent),
            diagnosticsEnabled: Binding(
                get: { privacy.diagnosticsConsent == .allowed }, set: privacy.setDiagnosticsConsent),
            analyticsStatus: status(privacy.analyticsConsent),
            diagnosticsStatus: status(privacy.diagnosticsConsent),
            serviceAvailable: privacy.isRuntimeAvailable,
            policyURL: Self.policyURL
        )
        .navigationTitle("プライバシーとデータ送信")
        .alert(
            "変更を保存できませんでした",
            isPresented: Binding(
                get: { privacy.persistenceError != nil },
                set: { if !$0 { privacy.dismissPersistenceError() } })
        ) {
            Button("確認", role: .cancel) { privacy.dismissPersistenceError() }
        } message: {
            Text(privacy.persistenceError ?? "")
        }

    }

    private func status(_ consent: TelemetryConsent) -> String {
        switch consent {
        case .unspecified: "未選択（送信しない）"
        case .allowed: "同意済み（いつでもオフにできます）"
        case .denied: "送信しない"
        }
    }
}
