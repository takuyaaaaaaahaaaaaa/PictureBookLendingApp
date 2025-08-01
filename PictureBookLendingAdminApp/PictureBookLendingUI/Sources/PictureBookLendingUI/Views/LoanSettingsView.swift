import SwiftUI

/// 貸出設定画面のPresentation View
///
/// 貸出期間などの設定を表示・編集するフォームです。
/// 設定の保存や検証はContainer Viewに委譲します。
public struct LoanSettingsView: View {
    @Binding var loanPeriodDays: Int
    @Binding var maxBooksPerUser: Int
    let onReset: () -> Void
    
    public init(
        loanPeriodDays: Binding<Int>,
        maxBooksPerUser: Binding<Int>,
        onReset: @escaping () -> Void
    ) {
        self._loanPeriodDays = loanPeriodDays
        self._maxBooksPerUser = maxBooksPerUser
        self.onReset = onReset
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Form {
                Section("貸出期間設定") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("貸出期間")
                            Spacer()
                            Text("\(loanPeriodDays)日")
                                .foregroundStyle(.secondary)
                        }
                        
                        Stepper(
                            "貸出期間: \(loanPeriodDays)日",
                            value: $loanPeriodDays,
                            in: 1...365
                        )
                        .labelsHidden()
                        
                        Text("絵本を貸し出してから返却期限までの日数です")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("貸出可能数設定") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("一人当たりの貸出可能数")
                            Spacer()
                            Text("\(maxBooksPerUser)冊")
                                .foregroundStyle(.secondary)
                        }
                        
                        Stepper(
                            "貸出可能数: \(maxBooksPerUser)冊",
                            value: $maxBooksPerUser,
                            in: 1...99
                        )
                        .labelsHidden()
                        
                        Text("一人の利用者が同時に借りられる絵本の最大数です")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            VStack(spacing: 12) {
                Button("デフォルトに戻す", action: onReset)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.orange)
                
                Text("デフォルト設定（14日・1冊）にリセットされます")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("貸出設定")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    NavigationStack {
        LoanSettingsView(
            loanPeriodDays: .constant(14),
            maxBooksPerUser: .constant(1),
            onReset: {}
        )
    }
}
