import SwiftUI

/// データ同期のコンテナビュー
///
/// データの同期・バックアップ機能を提供します。
struct DataSyncContainerView: View {
    @State private var lastSyncDate: Date?
    @State private var isSyncing = false
    @State private var alertState = AlertState()
    
    var body: some View {
        VStack(spacing: 20) {
            // 同期状態カード
            VStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                
                Text("データ同期")
                    .font(.headline)
                
                if let lastSyncDate = lastSyncDate {
                    Text("最終同期: \(lastSyncDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("まだ同期されていません")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // 同期オプション
            VStack(spacing: 16) {
                Button(action: performManualSync) {
                    HStack {
                        if isSyncing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("手動同期を実行")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSyncing)
                
                Button("データをリセット") {
                    confirmDataReset()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(isSyncing)
            }
            
            Spacer()
            
            // 注意事項
            VStack(alignment: .leading, spacing: 8) {
                Text("注意事項")
                    .font(.headline)
                
                Text("• データ同期機能は将来のアップデートで実装予定です")
                Text("• 現在はローカルストレージのみでデータを管理しています")
                Text("• データのバックアップは定期的に手動で行ってください")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle("データ同期")
        .navigationBarTitleDisplayMode(.large)
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            if alertState.title == "データリセット確認" {
                Button("リセット", role: .destructive) {
                    performDataReset()
                }
                Button("キャンセル", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(alertState.message)
        }
    }
    
    private func performManualSync() {
        isSyncing = true
        
        // 実際の同期処理の模擬
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒待機
            
            await MainActor.run {
                isSyncing = false
                lastSyncDate = Date()
                alertState = AlertState(
                    title: "同期完了",
                    message: "データの同期が正常に完了しました。"
                )
            }
        }
    }
    
    private func confirmDataReset() {
        alertState = AlertState(
            title: "データリセット確認",
            message: "すべてのデータが削除されます。この操作は取り消せません。本当に実行しますか？"
        )
    }
    
    private func performDataReset() {
        alertState = AlertState(
            title: "データリセット",
            message: "データリセット機能は安全のため無効化されています。"
        )
    }
}

#Preview {
    NavigationStack {
        DataSyncContainerView()
    }
}