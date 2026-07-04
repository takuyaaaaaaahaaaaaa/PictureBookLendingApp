import SwiftUI

/// 貸出ボタンのPresentation View
///
/// 純粋なUIコンポーネントとして貸出ボタンの表示を担当します。
/// アクション処理はContainer Viewに委譲します。
public struct LoanButtonView: View {
    /// ボタンのラベル（ホストする文脈に合わせて差し替え可能。例：貸出フローでは「借りる」）
    let title: String
    let onTap: () -> Void
    
    public init(title: String = "貸出", onTap: @escaping () -> Void) {
        self.title = title
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                    .font(.callout)
                Text(title)
                    .font(.callout)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        LoanButtonView(onTap: {
            print("貸出ボタンがタップされました")
        })
        
        // リスト内での表示例
        List {
            HStack {
                VStack(alignment: .leading) {
                    Text("はらぺこあおむし")
                        .font(.headline)
                    Text("エリック・カール")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                LoanButtonView(onTap: {
                    print("貸出ボタンがタップされました")
                })
            }
            .padding(.vertical, 4)
        }
    }
    .padding()
}
