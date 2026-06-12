import SwiftUI

/// 返却ボタンのPresentation View
///
/// 純粋なUIコンポーネントとして返却ボタンの表示を担当します。
/// アクション処理はContainer Viewに委譲します。
public struct ReturnButtonView: View {
    let onTap: () -> Void
    
    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.callout)
                Text("返却")
                    .font(.callout)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        ReturnButtonView(onTap: {
            print("返却ボタンがタップされました")
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
                
                ReturnButtonView(onTap: {
                    print("返却ボタンがタップされました")
                })
            }
            .padding(.vertical, 4)
        }
    }
    .padding()
}
