import SwiftUI

/// アプリ設定のコンテナビュー
///
/// アプリケーション全体の設定項目を管理します。
struct AppSettingsContainerView: View {
    @State private var defaultLoanDuration = 7
    @State private var enableNotifications = true
    @State private var autoBackup = false
    @State private var alertState = AlertState()
    
    var body: some View {
        Form {
            Section("貸出設定") {
                Stepper("デフォルト貸出期間: \(defaultLoanDuration)日", 
                       value: $defaultLoanDuration, 
                       in: 1...30)
                
                Toggle("期限切れ通知", isOn: $enableNotifications)
            }
            
            Section("データ管理") {
                Toggle("自動バックアップ", isOn: $autoBackup)
                
                Button("データエクスポート") {
                    exportData()
                }
                
                Button("データインポート") {
                    importData()
                }
            }
            
            Section("アプリ情報") {
                LabeledContent("バージョン", value: "1.0.0")
                LabeledContent("ビルド", value: "2024.1")
                
                Button("ライセンス情報") {
                    showLicenseInfo()
                }
            }
        }
        .navigationTitle("アプリ設定")
        .navigationBarTitleDisplayMode(.large)
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private func exportData() {
        alertState = AlertState(
            title: "データエクスポート",
            message: "データエクスポート機能は今後実装予定です。"
        )
    }
    
    private func importData() {
        alertState = AlertState(
            title: "データインポート",
            message: "データインポート機能は今後実装予定です。"
        )
    }
    
    private func showLicenseInfo() {
        alertState = AlertState(
            title: "ライセンス情報",
            message: "PictureBookLendingApp\n© 2024 All rights reserved."
        )
    }
}

#Preview {
    NavigationStack {
        AppSettingsContainerView()
    }
}