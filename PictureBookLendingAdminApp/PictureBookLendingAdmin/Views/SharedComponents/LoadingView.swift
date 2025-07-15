import SwiftUI

/// ローディング表示の共通UIコンポーネント
///
/// データ読み込み中に表示する統一されたローディングUIを提供します。
/// iPad横向きでの表示に最適化されています。
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .foregroundStyle(.secondary)
                .font(.body)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    LoadingView(message: "データを読み込み中...")
}