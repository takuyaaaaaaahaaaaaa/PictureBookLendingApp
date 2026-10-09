import SwiftUI

/// 初期設定の最後に任意送信の用途を説明し、両項目への同意または拒否を受け取る。
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
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
            .navigationTitle("データ送信について")
            #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
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
                    "機種・OS・アプリのバージョン、異常終了時の処理の記録、診断用IDをGoogleのFirebase Crashlyticsへ送り、不具合の原因調査に利用します。許可した時点と以後のアプリ起動時に、保存済みの診断情報の送信をアプリが要求します。同じ起動中の要求は一度です。同意前やオフ期間中の診断も送信対象になる場合があります。毎回の送信確認は行いません。"
            )
            Text("アプリが送信する利用状況イベントには、園児・保護者の名前、絵本の題名、検索文字列、貸出記録そのものを含めません。アプリからクラッシュ診断へ、これらを追加情報として付加する処理もありません。広告や他社アプリをまたぐ追跡にも利用しません。")
                .bold()
            Text(
                "後から「設定 → プライバシーとデータ送信」で項目ごとに変更できます。利用状況をオフにすると新たな収集を停止します。クラッシュ診断をオフにすると新たな送信要求を停止しますが、送信済み・送信開始済みの情報は取り消せません。"
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
            Text("「同意して貸出へ」を選ぶと、利用状況とクラッシュ診断の送信が両方オンになります。")
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onAllow) {
                Text("同意して貸出へ")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("privacy.allowAndStart")
            Button(action: onDecline) {
                Text("送信せずに貸出へ")
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
