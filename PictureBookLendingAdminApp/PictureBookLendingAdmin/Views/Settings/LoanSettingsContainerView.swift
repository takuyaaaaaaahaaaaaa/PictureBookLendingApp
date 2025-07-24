import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出設定のContainer View
///
/// 貸出設定の状態管理、バリデーション、保存処理を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct LoanSettingsContainerView: View {
    @Environment(LoanSettingsModel.self) private var loanSettingsModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var loanPeriodDays: Int = 14
    @State private var maxBooksPerUser: Int = 1
    @State private var alertState = AlertState()
    
    var body: some View {
        LoanSettingsView(
            loanPeriodDays: $loanPeriodDays,
            maxBooksPerUser: $maxBooksPerUser,
            onReset: handleReset
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("保存") {
                    handleSave()
                }
                .fontWeight(.semibold)
            }
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - Actions
    
    private func handleSave() {
        let newSettings = LoanSettings(
            defaultLoanPeriodDays: loanPeriodDays, maxBooksPerUser: maxBooksPerUser)
        
        guard newSettings.isValid() else {
            alertState = .error("設定値が無効です。貸出期間は1日〜365日、貸出可能数は1冊以上で設定してください。")
            return
        }
        
        do {
            try loanSettingsModel.updateSettings(newSettings)
            
            // 成功時は即座に画面を閉じる
            dismiss()
        } catch {
            alertState = .error("設定の保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func handleReset() {
        loanPeriodDays = LoanSettings.default.defaultLoanPeriodDays
        maxBooksPerUser = LoanSettings.default.maxBooksPerUser
        alertState = .success("デフォルト設定（\(loanPeriodDays)日・\(maxBooksPerUser)冊）にリセットしました")
    }
    
    private func loadCurrentSettings() {
        loanPeriodDays = loanSettingsModel.settings.defaultLoanPeriodDays
        maxBooksPerUser = loanSettingsModel.settings.maxBooksPerUser
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let loanSettingsModel = LoanSettingsModel(repository: mockFactory.loanSettingsRepository)
    
    NavigationStack {
        LoanSettingsContainerView()
            .environment(loanSettingsModel)
    }
}
