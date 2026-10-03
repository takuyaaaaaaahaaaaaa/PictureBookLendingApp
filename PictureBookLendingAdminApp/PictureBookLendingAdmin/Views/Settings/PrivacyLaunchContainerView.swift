import PictureBookLendingUI
import SwiftUI

/// 選択が保存されるまで起動画面を表示する。個別に選択済みの設定は上書きしない。
struct PrivacyLaunchContainerView<Content: View>: View {
    @Environment(TelemetryPrivacyController.self) private var privacy
    
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if privacy.needsInitialConsent {
            PrivacyConsentView(
                policyURL: PrivacySettingsContainerView.policyURL,
                onAllow: { privacy.completeInitialConsent(allowed: true) },
                onDecline: { privacy.completeInitialConsent(allowed: false) }
            )
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
        } else {
            content()
        }
    }
}
