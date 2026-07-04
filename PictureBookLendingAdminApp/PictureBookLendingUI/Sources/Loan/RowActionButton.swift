import SwiftUI

/// 行内アクションボタンのPresentation View
///
/// 純粋なUIコンポーネントとして行内のアクションボタン表示を担当します。
/// アクション処理はContainer Viewに委譲します。
/// ラベル・アイコン・色をホストする文脈に合わせて差し替えられます
/// （例：貸出フローの「借りる」＝青、「貸出中」の案内＝グレー。
/// 同じ形で並べることでボタン同士のデザインが揃う）。
public struct RowActionButton: View {
    /// ボタンのラベル（例：貸出フローでは「借りる」）
    let title: String
    /// 先頭のSFシンボル名
    let systemImage: String
    /// ボタンの背景色（主役の操作は青、案内などの脇役はグレー）
    let tint: Color
    let onTap: () -> Void
    
    public init(
        title: String = "貸出",
        systemImage: String = "plus.circle",
        tint: Color = .blue,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.callout)
                Text(title)
                    .font(.callout)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(tint)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        RowActionButton(onTap: {
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
                
                RowActionButton(onTap: {
                    print("貸出ボタンがタップされました")
                })
            }
            .padding(.vertical, 4)
        }
    }
    .padding()
}
