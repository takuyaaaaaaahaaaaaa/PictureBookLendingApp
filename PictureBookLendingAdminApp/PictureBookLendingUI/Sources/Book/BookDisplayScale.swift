import SwiftUI

/// 一覧の表示の大きさ（「大きく表示」トグルの状態）
///
/// 文字が見えづらい利用者向けに、表紙・タイトルを一回り大きくした表示へ
/// 切り替えられるようにする。モード（自動で戻る一時状態）ではなく、
/// もう一度切り替えるまで維持される永続的な表示設定
public enum BookDisplayScale: String, CaseIterable, Identifiable, Sendable {
    case standard
    case large
    
    public var id: String { rawValue }
    
    /// トグル操作で切り替わった先の値
    public var toggled: BookDisplayScale {
        self == .standard ? .large : .standard
    }
    
    /// グリッド・棚表示のセル最小幅（適応的グリッドの折り返し基準）
    var minCellWidth: CGFloat {
        switch self {
        case .standard: 140
        case .large: 210
        }
    }
    
    /// グリッドセルのタイトルフォント
    var gridTitleFont: Font {
        switch self {
        case .standard: .subheadline
        case .large: .title3
        }
    }
    
    /// リスト行のサムネイル幅
    var rowThumbnailWidth: CGFloat {
        switch self {
        case .standard: 50
        case .large: 80
        }
    }
    
    /// リスト行のサムネイル高さ
    var rowThumbnailHeight: CGFloat {
        switch self {
        case .standard: 65
        case .large: 104
        }
    }
    
    /// リスト行のタイトルフォント
    var rowTitleFont: Font {
        switch self {
        case .standard: .title3
        case .large: .title2
        }
    }
    
    /// リスト行の著者名フォント
    var rowAuthorFont: Font {
        switch self {
        case .standard: .subheadline
        case .large: .body
        }
    }
}

/// 「大きく表示」フローティングボタン（一覧の右下に重ねて置く）
///
/// 文字が見えづらい利用者が最初に見つけられるよう、表示メニューの中に隠さず
/// 画面上に常時見える大きなボタンにする。押すまで戻らないトグルで、
/// 大きい表示のままでも他の利用者の操作を妨げない
public struct BookDisplayScaleToggleButton: View {
    @Binding var scale: BookDisplayScale
    
    public init(scale: Binding<BookDisplayScale>) {
        self._scale = scale
    }
    
    public var body: some View {
        Button {
            withAnimation {
                scale = scale.toggled
            }
        } label: {
            Label(
                scale == .standard ? "大きく表示" : "ふつうに表示",
                systemImage: scale == .standard
                    ? "textformat.size.larger" : "textformat.size.smaller"
            )
            .font(.title3.bold())
            .padding(.horizontal, Layout.labelHorizontalPadding)
            .padding(.vertical, Layout.labelVerticalPadding)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .accessibilityLabel(scale == .standard ? "一覧を大きく表示" : "一覧をふつうの大きさで表示")
    }
    
    private enum Layout {
        /// ラベルの内側余白（遠目にも見つけやすい大きめの押下面にする）
        static let labelHorizontalPadding: CGFloat = 8
        static let labelVerticalPadding: CGFloat = 6
    }
}

#Preview {
    @Previewable @State var scale: BookDisplayScale = .standard
    
    VStack(spacing: 24) {
        Text("現在: \(scale.rawValue)")
        BookDisplayScaleToggleButton(scale: $scale)
    }
    .padding()
}
