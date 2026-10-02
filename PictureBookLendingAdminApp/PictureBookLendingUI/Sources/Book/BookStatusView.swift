import SwiftUI

/// 絵本の貸出ステータス表示コンポーネント
///
/// 設定画面などで絵本の貸出状況を表示するために使用します。
public struct BookStatusView: View {
    let isCurrentlyLent: Bool
    
    public init(isCurrentlyLent: Bool) {
        self.isCurrentlyLent = isCurrentlyLent
    }
    
    public var body: some View {
        Label(
            isCurrentlyLent ? "貸出中" : "貸出可",
            systemImage: isCurrentlyLent ? "book.closed" : "checkmark.circle"
        )
        .font(.caption.weight(.medium))
        .foregroundStyle(isCurrentlyLent ? AppColor.lent : AppColor.available)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            isCurrentlyLent ? AppColor.lentSurface : AppColor.available.opacity(0.1)
        )
        .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        BookStatusView(isCurrentlyLent: false)
        BookStatusView(isCurrentlyLent: true)
        
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
                
                BookStatusView(isCurrentlyLent: false)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("ぐりとぐら")
                        .font(.headline)
                    Text("中川李枝子")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                BookStatusView(isCurrentlyLent: true)
            }
        }
    }
    .padding()
}
