import SwiftUI

#if os(iOS)
    import UIKit
#endif

/// 家庭の枠1つ分の表示データ
///
/// 家庭の画面（返却・貸出の両文脈）で1枠＝家族1人の貸出状況を表します。
public struct FamilyLoanSlotDisplay: Identifiable, Equatable, Sendable {
    /// 枠の持ち主の利用者ID
    public let id: UUID
    /// 枠名（例：「園児の本」「保護者の本」）
    public let roleLabel: String
    /// 枠の持ち主の名前
    public let memberName: String
    /// 貸出中の図書（借りていなければnil）
    public let loan: FamilyLoanSlotLoan?

    public init(id: UUID, roleLabel: String, memberName: String, loan: FamilyLoanSlotLoan?) {
        self.id = id
        self.roleLabel = roleLabel
        self.memberName = memberName
        self.loan = loan
    }
}

/// 枠に表示する貸出中図書の情報
public struct FamilyLoanSlotLoan: Equatable, Sendable {
    /// 図書タイトル
    public let bookTitle: String
    /// 表紙画像のソース（ローカルパスまたはURL文字列。なければnil）
    public let imageURL: String?
    /// 返却期限の表示文字列（例：「6月20日（土）」）
    public let dueDateText: String
    /// 延滞中かどうか
    public let isOverdue: Bool

    public init(bookTitle: String, imageURL: String?, dueDateText: String, isOverdue: Bool) {
        self.bookTitle = bookTitle
        self.imageURL = imageURL
        self.dueDateText = dueDateText
        self.isOverdue = isOverdue
    }
}

/// 家庭の枠領域の文脈
public enum FamilyLoanSlotsMode: Equatable, Sendable {
    /// 返却タブから：貸出中の枠に「返却」ボタンを表示
    case returning
    /// 貸出フローから：空いている枠に「この枠で借りる」ボタンを表示。
    /// 貸出中の枠はコンパクト表示＋「返却」ボタン（先に返し忘れて枠が埋まっている人が
    /// その場で枠を空けて借り直せるように＝本の入れ替え）
    case borrowing
}

/// 家庭の枠領域のPresentation View
///
/// 家族全員の枠（園児の本・保護者の本）を縦に並べて表示します。
/// 返却タブのプッシュ先と貸出フローの枠確認の両方が、この同じ部品をホストします。
/// 文字・ボタンはタイポグラフィ方針（主動線は`.title3`以上・タップ領域44pt以上）に従います。
public struct FamilyLoanSlotsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let slots: [FamilyLoanSlotDisplay]
    let mode: FamilyLoanSlotsMode
    let onReturn: (FamilyLoanSlotDisplay) -> Void
    let onBorrow: (FamilyLoanSlotDisplay) -> Void

    private var isPhone: Bool {
        #if os(iOS)
            UIDevice.current.userInterfaceIdiom == .phone
        #else
            false
        #endif
    }

    private var dueDateLayout: AnyLayout {
        isPhone
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Layout.textSpacing))
            : AnyLayout(HStackLayout(spacing: Layout.headerSpacing))
    }

    private var lentCardLayout: AnyLayout {
        isPhone && dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Layout.headerSpacing))
            : AnyLayout(
                HStackLayout(spacing: isPhone ? Layout.headerSpacing : Layout.contentSpacing))
    }

    private enum Layout {
        static let slotSpacing: CGFloat = 24
        static let headerSpacing: CGFloat = 8
        static let contentSpacing: CGFloat = 16
        static let textSpacing: CGFloat = 6
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 16
        static let cardMinHeight: CGFloat = 104
        static let thumbnailWidth: CGFloat = 56
        static let thumbnailHeight: CGFloat = 72
        static let thumbnailCornerRadius: CGFloat = 6
        static let emptyDashLength: CGFloat = 6
        static let badgePaddingH: CGFloat = 8
        static let badgePaddingV: CGFloat = 3
    }

    public init(
        slots: [FamilyLoanSlotDisplay],
        mode: FamilyLoanSlotsMode,
        onReturn: @escaping (FamilyLoanSlotDisplay) -> Void,
        onBorrow: @escaping (FamilyLoanSlotDisplay) -> Void
    ) {
        self.slots = slots
        self.mode = mode
        self.onReturn = onReturn
        self.onBorrow = onBorrow
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Layout.slotSpacing) {
            ForEach(slots) { slot in
                slotSection(slot)
            }
        }
    }

    // MARK: - Private Views

    /// 枠1つ分：枠名ヘッダ＋カード
    private func slotSection(_ slot: FamilyLoanSlotDisplay) -> some View {
        VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            HStack(spacing: Layout.headerSpacing) {
                Text(slot.roleLabel)
                    .font(.headline)
                    .foregroundStyle(AppColor.libraryTitle)
                Text(slot.memberName)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.librarySecondaryText)
            }

            if let loan = slot.loan {
                // 貸出文脈では「すでに借りている本」は選べない情報なので、
                // 主役（空き枠・いま借りる本の表紙）に視線を譲るコンパクト表示にする
                if mode == .borrowing {
                    lentCompactCard(slot: slot, loan: loan)
                } else {
                    lentCard(slot: slot, loan: loan)
                }
            } else {
                emptyCard(slot: slot)
            }
        }
    }

    /// 貸出中の枠：表紙＋図書情報＋（返却文脈なら）返却ボタン
    private func lentCard(slot: FamilyLoanSlotDisplay, loan: FamilyLoanSlotLoan) -> some View {
        lentCardLayout {
            BookImageView(imageURL: loan.imageURL) {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
                    .font(.title2)
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: Layout.thumbnailWidth, height: Layout.thumbnailHeight)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Layout.thumbnailCornerRadius))

            VStack(alignment: .leading, spacing: Layout.textSpacing) {
                Text(loan.bookTitle)
                    .font(.title3.bold())
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(AppColor.libraryTitle)

                dueDateLayout {
                    Text("返却期限：\(loan.dueDateText)")
                        .font(.subheadline)
                        .foregroundStyle(loan.isOverdue ? AppColor.overdue : .secondary)
                    if loan.isOverdue {
                        Label("延滞", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, Layout.badgePaddingH)
                            .padding(.vertical, Layout.badgePaddingV)
                            .background(AppColor.overdue, in: Capsule())
                            .foregroundStyle(AppColor.onEmphasis)
                    }
                }
                .frame(maxWidth: isPhone ? .infinity : nil, alignment: .leading)
            }
            .frame(maxWidth: isPhone ? .infinity : nil, alignment: .leading)

            if !isPhone {
                Spacer(minLength: Layout.contentSpacing)
            }

            if mode == .returning {
                Button("返却") {
                    onReturn(slot)
                }
                .font(.title3)
                .buttonStyle(.borderedProminent)
                .tint(AppColor.libraryAction)
                .foregroundStyle(AppColor.onEmphasis)
                .controlSize(.large)
                .fixedSize(horizontal: isPhone, vertical: false)
                .frame(minWidth: isPhone ? 44 : nil, minHeight: isPhone ? 44 : nil)
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, minHeight: Layout.cardMinHeight, alignment: .leading)
        .background {
            ReturnLoanCardBackground(cornerRadius: Layout.cardCornerRadius)
        }
    }

    /// 貸出中の枠（貸出文脈のコンパクト表示）：表紙なしの1行＋「返却」ボタン
    ///
    /// 本のアイコン＋書名＋期限をグレーで控えめに示す。延滞だけは赤で残す。
    /// 「返却」ボタンは、先に返し忘れて枠が埋まっている人がその場で枠を空けて
    /// 借り直せるようにするリカバリー導線（原則2「ミスは前提、リカバリーは1タップ」）
    @ViewBuilder
    private func lentCompactCard(slot: FamilyLoanSlotDisplay, loan: FamilyLoanSlotLoan)
        -> some View
    {
        if isPhone {
            VStack(alignment: .leading, spacing: Layout.headerSpacing) {
                Label(loan.bookTitle, systemImage: "book.closed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("返却期限：\(loan.dueDateText)")
                    .font(.subheadline)
                    .foregroundStyle(loan.isOverdue ? AppColor.overdue : .secondary)
                if loan.isOverdue {
                    Label("延滞", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, Layout.badgePaddingH)
                        .padding(.vertical, Layout.badgePaddingV)
                        .background(AppColor.overdue, in: Capsule())
                        .foregroundStyle(AppColor.onEmphasis)
                }

                Button("返却") {
                    onReturn(slot)
                }
                .font(.title3)
                .buttonStyle(.bordered)
                .tint(AppColor.libraryAction)
                .foregroundStyle(AppColor.libraryAction)
                .controlSize(.large)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .trailing)
            }
            .padding(Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppColor.cardSurface,
                in: RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
            )
        } else {
            HStack(spacing: Layout.headerSpacing) {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
                Text(loan.bookTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer(minLength: Layout.contentSpacing)

                Text("返却期限：\(loan.dueDateText)")
                    .font(.subheadline)
                    .foregroundStyle(loan.isOverdue ? AppColor.overdue : .secondary)
                if loan.isOverdue {
                    Label("延滞", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .padding(.horizontal, Layout.badgePaddingH)
                        .padding(.vertical, Layout.badgePaddingV)
                        .background(AppColor.overdue, in: Capsule())
                        .foregroundStyle(AppColor.onEmphasis)
                }

                // 文字とタップ領域は揃え、借り直すための補助操作として控えめに示す
                Button("返却") {
                    onReturn(slot)
                }
                .font(.title3)
                .buttonStyle(.bordered)
                .tint(AppColor.libraryAction)
                .foregroundStyle(AppColor.libraryAction)
                .controlSize(.large)
            }
            .padding(Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                AppColor.cardSurface,
                in: RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
            )
        }
    }

    /// 空き枠：破線の枠＋（貸出文脈なら）借りるボタン
    private func emptyCard(slot: FamilyLoanSlotDisplay) -> some View {
        let isPhoneBorrowing = isPhone && mode == .borrowing
        return VStack(alignment: .leading, spacing: Layout.headerSpacing) {
            HStack(spacing: Layout.contentSpacing) {
                Text("借りていません")
                    .font(.title3)
                    .foregroundStyle(.tertiary)

                if !isPhoneBorrowing {
                    Spacer(minLength: Layout.contentSpacing)
                }

                if mode == .borrowing && !isPhoneBorrowing {
                    RowActionButton(
                        title: "この枠で借りる", tint: AppColor.borrowAction,
                        foreground: AppColor.borrowActionForeground, hasSubtleDepth: true,
                        font: .title3
                    ) {
                        onBorrow(slot)
                    }
                }
            }
            if isPhoneBorrowing {
                RowActionButton(
                    title: dynamicTypeSize.isAccessibilitySize ? "借りる" : "この枠で借りる",
                    tint: AppColor.borrowAction,
                    foreground: AppColor.borrowActionForeground, hasSubtleDepth: true,
                    font: .title3
                ) {
                    onBorrow(slot)
                }
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .trailing)
                .accessibilityLabel("この枠で借りる")
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, minHeight: Layout.cardMinHeight, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                .strokeBorder(
                    .quaternary,
                    style: StrokeStyle(lineWidth: 1.5, dash: [Layout.emptyDashLength]))
        )
    }
}

#Preview("返却文脈") {
    let childId = UUID()
    let guardianId = UUID()

    ScrollView {
        FamilyLoanSlotsView(
            slots: [
                FamilyLoanSlotDisplay(
                    id: childId, roleLabel: "園児の本", memberName: "いとう さくら",
                    loan: FamilyLoanSlotLoan(
                        bookTitle: "ぐりとぐら", imageURL: nil,
                        dueDateText: "6月20日（土）", isOverdue: false)),
                FamilyLoanSlotDisplay(
                    id: guardianId, roleLabel: "保護者の本", memberName: "伊藤 由美子",
                    loan: FamilyLoanSlotLoan(
                        bookTitle: "だいくとおにろく", imageURL: nil,
                        dueDateText: "6月14日（日）", isOverdue: true)),
            ],
            mode: .returning,
            onReturn: { _ in },
            onBorrow: { _ in }
        )
        .padding()
    }
}

#Preview("貸出文脈（枠選択）") {
    let childId = UUID()
    let guardianId = UUID()

    ScrollView {
        FamilyLoanSlotsView(
            slots: [
                FamilyLoanSlotDisplay(
                    id: childId, roleLabel: "園児の本", memberName: "いとう さくら",
                    loan: FamilyLoanSlotLoan(
                        bookTitle: "ぐりとぐら", imageURL: nil,
                        dueDateText: "6月20日（土）", isOverdue: false)),
                FamilyLoanSlotDisplay(
                    id: guardianId, roleLabel: "保護者の本", memberName: "伊藤 由美子", loan: nil),
            ],
            mode: .borrowing,
            onReturn: { _ in },
            onBorrow: { _ in }
        )
        .padding()
    }
}

/// 架空の貸出データ。返却、空枠、Undoを同じプレビューで確認する。
private struct FamilyLoanSlotsLayoutPreview: View {
    let mode: FamilyLoanSlotsMode
    let width: CGFloat
    @State private var returned = false

    private let childID = UUID()
    private let guardianID = UUID()

    var body: some View {
        ScrollView {
            FamilyLoanSlotsView(
                slots: [
                    FamilyLoanSlotDisplay(
                        id: childID, roleLabel: "園児の本", memberName: "さくら",
                        loan: returned
                            ? nil
                            : FamilyLoanSlotLoan(
                                bookTitle: "はみがきあそびと長い日本語のタイトル",
                                imageURL: nil, dueDateText: "6月20日（土）", isOverdue: false)),
                    FamilyLoanSlotDisplay(
                        id: guardianID, roleLabel: "保護者の本", memberName: "はるか",
                        loan: FamilyLoanSlotLoan(
                            bookTitle: "A Very Long Picture Book Title for Testing",
                            imageURL: nil, dueDateText: "6月14日（日）", isOverdue: true)),
                ],
                mode: mode,
                onReturn: { _ in returned = true },
                onBorrow: { _ in }
            )
            if returned {
                Button("元に戻す") { returned = false }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .trailing)
            }
        }
        .padding()
        .frame(width: width)
    }
}

#Preview("iPhone 320・返却") {
    FamilyLoanSlotsLayoutPreview(mode: .returning, width: 320)
}

#Preview("iPhone 390・貸出枠") {
    FamilyLoanSlotsLayoutPreview(mode: .borrowing, width: 390)
}

#Preview("iPhone 375・AX3") {
    FamilyLoanSlotsLayoutPreview(mode: .returning, width: 375)
        .dynamicTypeSize(.accessibility3)
}

#Preview("iPhone 320・貸出枠・AX3") {
    FamilyLoanSlotsLayoutPreview(mode: .borrowing, width: 320)
        .dynamicTypeSize(.accessibility3)
}

#Preview("iPad 744・AX3") {
    FamilyLoanSlotsLayoutPreview(mode: .borrowing, width: 744)
        .dynamicTypeSize(.accessibility3)
}
