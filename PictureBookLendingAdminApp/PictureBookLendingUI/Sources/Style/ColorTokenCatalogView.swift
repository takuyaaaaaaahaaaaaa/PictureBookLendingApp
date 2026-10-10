import SwiftUI

/// 明暗のトークンと実際の操作・状態表示を同時に比較するカタログ。
public struct ColorTokenCatalogView: View {
    public init() {}

    public var body: some View {
        // 狭幅では横スクロールし、各見本の幅を保つ。
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                samples(title: "ライト", scheme: .light)
                samples(title: "ダーク", scheme: .dark)
            }
        }
    }

    private func samples(title: String, scheme: ColorScheme) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.headline)
            token("accent：操作", symbol: "hand.tap", color: AppColor.accent)
            token("libraryTitle：見出し", symbol: "textformat", color: AppColor.libraryTitle)
            token(
                "librarySecondaryText：補足", symbol: "text.alignleft",
                color: AppColor.librarySecondaryText)
            token("libraryAction：表示切替・返却", symbol: "arrow.up.right", color: AppColor.libraryAction)
            token(
                "borrowAction：借りる", symbol: "plus.circle", color: AppColor.borrowAction,
                foreground: AppColor.borrowActionForeground)
            Label("borrowActionForeground：借りるの文字", systemImage: "plus.circle")
                .foregroundStyle(AppColor.borrowActionForeground)
                .padding(8)
                .background(AppColor.borrowAction, in: RoundedRectangle(cornerRadius: 8))
            Label("returnCardBorder：カードの縁", systemImage: "rectangle")
                .foregroundStyle(AppColor.returnCardBorder)
            Label("borrowerCardSurface：利用者・完了通知の面", systemImage: "person.text.rectangle")
                .foregroundStyle(AppColor.libraryTitle)
                .padding(8)
                .background(AppColor.borrowerCardSurface, in: RoundedRectangle(cornerRadius: 8))
            Label("lentForeground：貸出中の文字", systemImage: "book.closed")
                .foregroundStyle(AppColor.lentForeground)
            Label("lentSurface：貸出中の面", systemImage: "book.closed")
                .foregroundStyle(AppColor.lentForeground)
                .padding(8)
                .background(AppColor.lentSurface, in: RoundedRectangle(cornerRadius: 8))
            token("available：貸出可", symbol: "checkmark.circle", color: AppColor.available)
            token("overdue：延滞", symbol: "exclamationmark.triangle", color: AppColor.overdue)
            token("returned：返却済み", symbol: "checkmark.circle.fill", color: AppColor.returned)
            token("destructive：削除", symbol: "trash", color: AppColor.destructive)
            Label("cardSurface：カード背景", systemImage: "rectangle")
                .padding(8)
                .background(AppColor.cardSurface, in: RoundedRectangle(cornerRadius: 8))
            Label("chipSurface：補助ラベル背景", systemImage: "capsule")
                .padding(8)
                .background(AppColor.chipSurface, in: Capsule())
            Text("状態バッジは専用の面＋文字。貸出中の案内は中立色。")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(spacing: 12) {
                BookDisplayScaleToggleButton(scale: .constant(.standard))
                RowActionButton(
                    title: "借りる", tint: AppColor.borrowAction,
                    foreground: AppColor.borrowActionForeground, hasSubtleDepth: true,
                    onTap: {}
                )
                RowActionButton(
                    title: "貸出中", systemImage: "book.closed", tint: AppColor.chipSurface,
                    foreground: AppColor.libraryTitle, border: AppColor.returnCardBorder, onTap: {})
                BookStatusView(isCurrentlyLent: false)
                BookStatusView(isCurrentlyLent: true)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background { LibrarySurfaceBackgroundView() }
        }
        .padding(16)
        .frame(width: 340, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .environment(\.colorScheme, scheme)
    }

    private func token(
        _ title: String, symbol: String, color: Color, foreground: Color = AppColor.onEmphasis
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .foregroundStyle(color)
            Label("文字＋アイコン", systemImage: symbol)
                .foregroundStyle(foreground)
                .padding(8)
                .background(color, in: RoundedRectangle(cornerRadius: 8))
        }
        .font(.subheadline)
    }
}
