import SwiftUI

/// 任意送信の説明と選択。保存とSDK制御はContainerへ委譲する。
public struct PrivacySettingsView: View {
    @Binding var analyticsEnabled: Bool
    @Binding var diagnosticsEnabled: Bool
    let analyticsStatus: String
    let diagnosticsStatus: String
    let serviceAvailable: Bool
    let policyURL: URL
    
    public init(
        analyticsEnabled: Binding<Bool>, diagnosticsEnabled: Binding<Bool>,
        analyticsStatus: String, diagnosticsStatus: String,
        serviceAvailable: Bool, policyURL: URL
    ) {
        _analyticsEnabled = analyticsEnabled
        _diagnosticsEnabled = diagnosticsEnabled
        self.analyticsStatus = analyticsStatus
        self.diagnosticsStatus = diagnosticsStatus
        self.serviceAvailable = serviceAvailable
        self.policyURL = policyURL
    }
    
    public var body: some View {
        Form {
            Section("送信は任意です") {
                Text("どちらもオフのまま、貸出・返却・図書と利用者の管理を利用できます。管理者がこの端末の送信を選び、いつでもこの画面で取り消せます。")
                Text("園児・保護者の名前、絵本の題名、検索文字列、貸出記録そのものは分析・診断へ送りません。同意しても送信対象にはなりません。")
            }
            Section {
                Toggle("利用状況の送信に同意する", isOn: $analyticsEnabled)
                    .accessibilityIdentifier("privacy.analytics")
                Text(analyticsStatus).font(.caption).foregroundStyle(.secondary)
                Text(
                    "操作の種類・件数・所要時間、アプリの利用状況、端末を区別する広告用ではないIDを、GoogleのFirebase Analyticsへ送ります。使いやすさの改善に利用します。広告や他社アプリをまたぐ追跡には利用しません。"
                )
            } header: {
                Text("利用状況")
            } footer: {
                Text("オフにすると新たな収集を停止し、この端末の分析データとアプリインスタンスIDをリセットします。サーバーへ送信済みの情報を削除する操作ではありません。")
            }
            Section {
                Toggle("クラッシュ診断の自動送信を許可する", isOn: $diagnosticsEnabled)
                    .accessibilityIdentifier("privacy.diagnostics")
                Text(diagnosticsStatus).font(.caption).foregroundStyle(.secondary)
                Text(
                    "端末の機種・OS・アプリのバージョン、異常終了時の処理の記録、診断用IDをGoogleのFirebase Crashlyticsへ送ります。不具合の原因調査に利用します。許可すると、同意前を含めて端末に保存済みの診断も送信対象になります。"
                )
            } header: {
                Text("クラッシュ診断")
            } footer: {
                Text(
                    "初回の許可後は毎回の操作は不要です。クラッシュ情報を端末に記録し、通常は次回の起動時に自動送信します。オフは次回起動から反映され、送信を開始済みの情報は取り消せません。未送信の診断は端末に残る場合があり、後で再び許可すると送信対象になります。"
                )
            }
            Section("保存と削除") {
                Text(
                    "利用者・図書・貸出記録は端末内に保存します。不要になった情報は管理画面や「端末初期化」から削除できます。書き出したバックアップは、保存先で別途管理・削除してください。"
                )
                Text(
                    "送信したクラッシュ情報はFirebaseの方針に従い90日保持した後、稼働系とバックアップから削除が始まります。90日目に削除が完了するという意味ではありません。利用状況の保持はGoogle Analyticsの設定・データ種別によって異なり、集計データには別の扱いがあります。"
                )
                Text(
                    "送信済み情報の削除に関するお問い合わせは、公開ポリシーの連絡先へお願いします。名前や広告IDを送信していないため、個人を特定して削除できない場合があります。"
                )
            }
            Section("外部への通信") {
                Text(
                    "書誌情報を検索するときは、ISBN・書名・著者名を楽天ブックスAPIへ送ります。これは図書登録のための通信で、上の分析・診断の選択とは別です。利用者の情報は送りません。"
                )
                Link("公開プライバシーポリシーを読む", destination: policyURL)
            }
            if !serviceAvailable && (analyticsEnabled || diagnosticsEnabled) {
                Section { Text("このビルドでは送信サービスを利用できません。選択内容は端末に保存されています。貸出・返却はそのまま利用できます。") }
            }
        }
    }
}
