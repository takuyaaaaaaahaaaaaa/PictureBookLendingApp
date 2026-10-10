import SwiftUI

/// 行内アクションボタンのPresentation View
///
/// 純粋なUIコンポーネントとして行内のアクションボタン表示を担当します。
/// アクション処理はContainer Viewに委譲します。
/// ラベル・アイコン・色をホストする文脈に合わせて差し替えられます
/// （例：貸出フローの「借りる」＝緑、「貸出中」の案内＝紙になじむ中立色。
/// 同じ形で並べることでボタン同士のデザインが揃う）。
public struct RowActionButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    /// ボタンのラベル（例：貸出フローでは「借りる」）
    let title: String
    /// 先頭のSFシンボル名
    let systemImage: String
    /// ボタンの背景色（借りるはborrowAction、貸出中の案内はchipSurface）
    let tint: Color
    let foreground: Color
    /// フラットな面の縁。奥行き仕上げでは暗色の文字色から縁を作る。
    let border: Color
    let hasSubtleDepth: Bool
    let font: Font
    let onTap: () -> Void

    public init(
        title: String = "貸出",
        systemImage: String = "plus.circle",
        tint: Color = AppColor.accent,
        foreground: Color = AppColor.onEmphasis,
        border: Color = .clear,
        hasSubtleDepth: Bool = false,
        font: Font = .body,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.foreground = foreground
        self.border = border
        self.hasSubtleDepth = hasSubtleDepth
        self.font = font
        self.onTap = onTap
    }

    private enum Layout {
        /// 片手親指で押せるタップ領域の最小高さ（DESIGN_PRINCIPLES.md §5準拠）
        static let minTapTargetHeight: CGFloat = 44
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(font)
                Text(title)
                    .font(font)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .frame(minHeight: Layout.minTapTargetHeight)
            .background { buttonBackground }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 8)
        let isDark = colorScheme == .dark
        if hasSubtleDepth {
            shape.fill(tint)
                .overlay {
                    shape.fill(
                        LinearGradient(
                            colors: [
                                // ライトの光を0.06に抑え、白文字との4.5:1以上を保つ。
                                .white.opacity(isDark ? 0.10 : 0.06),
                                .clear,
                                .black.opacity(isDark ? 0.16 : 0.08),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .overlay {
                    if isDark {
                        shape.strokeBorder(
                            LinearGradient(
                                colors: [foreground.opacity(0.85), foreground.opacity(0.50)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: colorSchemeContrast == .increased ? 2 : 0.75
                        )
                    }
                }
                .shadow(color: .black.opacity(isDark ? 0.30 : 0.16), radius: 3, y: 2)
        } else {
            shape.fill(tint)
                .overlay {
                    shape.strokeBorder(
                        border, lineWidth: colorSchemeContrast == .increased ? 2 : 0.75
                    )
                }
        }
    }

}

#Preview("借りる・ライト") {
    VStack(spacing: 16) {
        RowActionButton(
            title: "借りる", tint: AppColor.borrowAction, foreground: AppColor.borrowActionForeground,
            hasSubtleDepth: true, onTap: {}
        )

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

                RowActionButton(
                    title: "借りる", tint: AppColor.borrowAction,
                    foreground: AppColor.borrowActionForeground, hasSubtleDepth: true,
                    onTap: {}
                )
            }
            .padding(.vertical, 4)
        }
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("借りる・ダーク") {
    VStack(spacing: 24) {
        RowActionButton(
            title: "借りる", tint: AppColor.borrowAction,
            foreground: AppColor.borrowActionForeground, hasSubtleDepth: true, onTap: {}
        )
        RowActionButton(
            title: "貸出中", systemImage: "book.closed", tint: AppColor.chipSurface,
            foreground: AppColor.libraryTitle, border: AppColor.returnCardBorder, onTap: {}
        )
    }
    .padding(32)
    .background { LibrarySurfaceBackgroundView() }
    .preferredColorScheme(.dark)
}
