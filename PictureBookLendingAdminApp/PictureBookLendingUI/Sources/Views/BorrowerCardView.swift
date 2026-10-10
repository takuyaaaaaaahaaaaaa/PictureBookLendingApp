import SwiftUI

/// 一覧とコレクションで共用する利用者カード。
/// 列数や選択処理はホストが持ち、ここは姓名・状態・必要な開示表示を担当する。
public struct BorrowerCardView: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @ScaledMetric(relativeTo: .title3) private var nameHeight = Layout.nameHeight
    @ScaledMetric(relativeTo: .caption) private var badgeHeight = Layout.badgeHeight

    public let row: BorrowerRowDisplay
    public let showsDisclosureIndicator: Bool

    public init(row: BorrowerRowDisplay, showsDisclosureIndicator: Bool = false) {
        self.row = row
        self.showsDisclosureIndicator = showsDisclosureIndicator
    }

    private enum Layout {
        static let padding: CGFloat = 12
        static let spacing: CGFloat = 8
        static let cornerRadius: CGFloat = 14
        static let nameHeight: CGFloat = 50
        static let badgeHeight: CGFloat = 20
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            HStack(alignment: .top, spacing: Layout.spacing) {
                Text(row.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColor.libraryTitle)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                if showsDisclosureIndicator {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColor.libraryAction)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: nameHeight, alignment: .topLeading)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Layout.spacing) { BorrowerBadgesView(row: row) }
                VStack(alignment: .leading, spacing: Layout.spacing) {
                    BorrowerBadgesView(row: row)
                }
            }
            .frame(minHeight: badgeHeight, alignment: .leading)
        }
        .padding(Layout.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColor.borrowerCardSurface, in: RoundedRectangle(cornerRadius: Layout.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .strokeBorder(
                    AppColor.returnCardBorder,
                    lineWidth: colorSchemeContrast == .increased ? 2 : 1
                )
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct BorrowerBadgesView: View {
    let row: BorrowerRowDisplay

    private enum Layout {
        static let badgePaddingH: CGFloat = 8
        static let badgePaddingV: CGFloat = 3
    }

    @ViewBuilder
    var body: some View {
        if row.isOverdue {
            Label("延滞", systemImage: "exclamationmark.triangle.fill")
                .labelStyle(.titleAndIcon)
                .font(.caption.bold())
                .padding(.horizontal, Layout.badgePaddingH)
                .padding(.vertical, Layout.badgePaddingV)
                .background(AppColor.overdue, in: Capsule())
                .foregroundStyle(AppColor.onEmphasis)
                .fixedSize()
        }

        if row.hasNoOpenSlot {
            // 行はタップ可能なままにし、家庭の画面で枠が使用中である理由を見せる。
            Label("空き枠なし", systemImage: "book.closed")
                .labelStyle(.titleAndIcon)
                .font(.caption.bold())
                .padding(.horizontal, Layout.badgePaddingH)
                .padding(.vertical, Layout.badgePaddingV)
                .background(AppColor.lentSurface, in: Capsule())
                .foregroundStyle(AppColor.lentForeground)
                .fixedSize()
        }

        if row.isGuardian {
            Text("保護者")
                .font(.caption)
                .padding(.horizontal, Layout.badgePaddingH)
                .padding(.vertical, Layout.badgePaddingV)
                .background(AppColor.chipSurface, in: Capsule())
                .foregroundStyle(AppColor.librarySecondaryText)
                .fixedSize()
        }
    }
}

