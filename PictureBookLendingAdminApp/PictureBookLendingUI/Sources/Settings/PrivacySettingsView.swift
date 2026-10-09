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
                Text("アプリが送信する利用状況イベントには、園児・保護者の名前、絵本の題名、検索文字列、貸出記録そのものを含めません。アプリからクラッシュ診断へ、これらを追加情報として付加する処理もありません。")
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
                Toggle("クラッシュ診断の送信に同意する", isOn: $diagnosticsEnabled)
                    .accessibilityIdentifier("privacy.diagnostics")
                Text(diagnosticsStatus).font(.caption).foregroundStyle(.secondary)
                Text(
                    "端末の機種・OS・アプリのバージョン、異常終了時の処理の記録、診断用IDをGoogleのFirebase Crashlyticsへ送ります。不具合の原因調査に利用します。許可すると、同意前を含めて端末に保存済みの診断も送信対象になります。"
                )
            } header: {
                Text("クラッシュ診断")
            } footer: {
                Text(
                    "許可した時点と以後のアプリ起動時に、保存済みの診断情報の送信をアプリが要求します。同じ起動中の要求は一度です。毎回の送信確認は行いません。オフにすると新たな送信要求を停止しますが、送信済み・送信開始済みの情報は取り消せません。未送信の診断は端末に残る場合があり、後で再び許可すると送信対象になります。"
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
                    "送信済み情報の削除に関するお問い合わせは、公開ポリシーの連絡先へお願いします。利用者の名前や広告IDで分析・診断データを管理していないため、特定の利用者に対応する情報を識別して削除できない場合があります。"
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
