import SwiftUI

/// 管理番号表示用のバッジコンポーネント
/// BookListViewとBookBulkAddViewで統一されたUIを提供
public struct ManagementNumberBadge: View {
    let text: String
    let style: Style
    
    public enum Style {
        case primary  // 通常の青色
        case success  // 成功時の緑色
        case secondary  // セカンダリ色
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return .blue.opacity(0.1)
            case .success:
                return .green.opacity(0.1)
            case .secondary:
                return .gray.opacity(0.1)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary:
                return .blue
            case .success:
                return .green
            case .secondary:
                return .secondary
            }
        }
    }
    
    public init(text: String, style: Style = .primary) {
        self.text = text
        self.style = style
    }
    
    public var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(style.backgroundColor)
            .foregroundStyle(style.foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    VStack(spacing: 8) {
        ManagementNumberBadge(text: "あ001", style: .primary)
        ManagementNumberBadge(text: "か123", style: .success)
        ManagementNumberBadge(text: "さ456", style: .secondary)
    }
    .padding()
}
