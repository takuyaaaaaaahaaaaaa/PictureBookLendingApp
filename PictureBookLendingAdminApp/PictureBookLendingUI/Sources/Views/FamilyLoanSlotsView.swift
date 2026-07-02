import SwiftUI

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
    /// 貸出フローから：空いている枠に「この枠で借りる」ボタンを表示
    case borrowing
}

/// 家庭の枠領域のPresentation View
///
/// 家族全員の枠（園児の本・保護者の本）を縦に並べて表示します。
/// 返却タブのプッシュ先と貸出フローの枠確認の両方が、この同じ部品をホストします。
/// 文字・ボタンはタイポグラフィ方針（主動線は`.title3`以上・タップ領域44pt以上）に従います。
public struct FamilyLoanSlotsView: View {
    let slots: [FamilyLoanSlotDisplay]
    let mode: FamilyLoanSlotsMode
    let onReturn: (FamilyLoanSlotDisplay) -> Void
    let onBorrow: (FamilyLoanSlotDisplay) -> Void
    
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
                Text(slot.memberName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let loan = slot.loan {
                lentCard(slot: slot, loan: loan)
            } else {
                emptyCard(slot: slot)
            }
        }
    }
    
    /// 貸出中の枠：表紙＋図書情報＋（返却文脈なら）返却ボタン
    private func lentCard(slot: FamilyLoanSlotDisplay, loan: FamilyLoanSlotLoan) -> some View {
        HStack(spacing: Layout.contentSpacing) {
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
                
                HStack(spacing: Layout.headerSpacing) {
                    Text("返却期限：\(loan.dueDateText)")
                        .font(.subheadline)
                        .foregroundStyle(loan.isOverdue ? .red : .secondary)
                    if loan.isOverdue {
                        Text("延滞")
                            .font(.caption.bold())
                            .padding(.horizontal, Layout.badgePaddingH)
                            .padding(.vertical, Layout.badgePaddingV)
                            .background(.red, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
            }
            
            Spacer(minLength: Layout.contentSpacing)
            
            if mode == .returning {
                Button("返却") {
                    onReturn(slot)
                }
                .font(.title3)
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, minHeight: Layout.cardMinHeight, alignment: .leading)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
        )
    }
    
    /// 空き枠：破線の枠＋（貸出文脈なら）借りるボタン
    private func emptyCard(slot: FamilyLoanSlotDisplay) -> some View {
        HStack(spacing: Layout.contentSpacing) {
            Text("借りていません")
                .font(.title3)
                .foregroundStyle(.tertiary)
            
            Spacer(minLength: Layout.contentSpacing)
            
            if mode == .borrowing {
                Button("この枠で借りる") {
                    onBorrow(slot)
                }
                .font(.title3)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
