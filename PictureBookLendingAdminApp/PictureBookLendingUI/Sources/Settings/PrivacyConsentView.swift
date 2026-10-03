import SwiftUI

/// 起動時に任意送信の用途を説明し、両項目への同意または拒否を受け取る。
public struct PrivacyConsentView: View {
    let policyURL: URL
    let onAllow: () -> Void
    let onDecline: () -> Void
    
    public init(
        policyURL: URL, onAllow: @escaping () -> Void, onDecline: @escaping () -> Void
    ) {
        self.policyURL = policyURL
        self.onAllow = onAllow
        self.onDecline = onDecline
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Label("えほん台帳へようこそ", systemImage: "book.closed")
                    .font(.title)
                    .accessibilityAddTraits(.isHeader)
                PrivacyConsentIntroduction()
                PrivacyConsentDataExplanation()
                PrivacyConsentActions(onAllow: onAllow, onDecline: onDecline)
                Link("公開プライバシーポリシーを読む", destination: policyURL)
            }
            .frame(maxWidth: 600, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(.background)
        .accessibilityIdentifier("privacy.initialConsent")
    }
}

private struct PrivacyConsentIntroduction: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("アプリの改善にご協力ください")
                .font(.title2)
                .accessibilityAddTraits(.isHeader)
            Text("この端末の管理者の方が、利用状況とクラッシュ診断の送信を選んでください。同意するまで、どちらも送信しません。")
            Text("送信せずに始めても、貸出・返却などすべての機能を利用できます。")
        }
    }
}

private struct PrivacyConsentDataExplanation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            PrivacyConsentPurposeSection(
                title: "利用状況",
                explanation:
                    "操作の種類・件数・所要時間、アプリの利用状況、広告用ではないIDをGoogleのFirebase Analyticsへ送り、使いやすさの改善に利用します。"
            )
            PrivacyConsentPurposeSection(
                title: "クラッシュ診断",
                explanation:
                    "機種・OS・アプリのバージョン、異常終了時の処理の記録、診断用IDをGoogleのFirebase Crashlyticsへ送り、不具合の原因調査に利用します。許可すると、同意前を含む端末に保存済みの診断も送信対象になり、通常は次回の起動時に自動送信します。"
            )
            Text("園児・保護者の名前、絵本の題名、検索文字列、貸出記録そのものは分析・診断へ送りません。広告や他社アプリをまたぐ追跡にも利用しません。")
                .bold()
            Text(
                "後から「設定 → プライバシーとデータ送信」で項目ごとに変更できます。利用状況のオフはその場で、クラッシュ診断のオフは次回起動から反映します。送信済み・送信開始済みの情報は取り消せません。"
            )
            .foregroundStyle(.secondary)
        }
    }
}

private struct PrivacyConsentPurposeSection: View {
    let title: LocalizedStringResource
    let explanation: LocalizedStringResource
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3).accessibilityAddTraits(.isHeader)
            Text(explanation)
        }
    }
}

private struct PrivacyConsentActions: View {
    let onAllow: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("「同意して始める」を選ぶと、利用状況とクラッシュ診断の送信が両方オンになります。")
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onAllow) {
                Text("同意して始める")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("privacy.allowAndStart")
            Button(action: onDecline) {
                Text("送信せずに始める")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("privacy.declineAndStart")
        }
        .controlSize(.large)
    }
}

#Preview {
    PrivacyConsentView(
        policyURL: URL(string: "https://example.com/privacy")!,
        onAllow: {}, onDecline: {})
}
