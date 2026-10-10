import PictureBookLendingDomain
import SwiftUI

/// 借用者一覧の1行分の表示データ
///
/// プライバシー配慮のため、一覧に出すのは名前・保護者ラベル・延滞マークまで。
/// 書名・期限は家庭の画面でだけ表示する（SCREEN_DESIGN_PHASE2 §3）。
public struct BorrowerRowDisplay: Identifiable, Equatable, Sendable {
    /// 借用者の利用者ID
    public let id: UUID
    /// 借用者の名前
    public let name: String
    /// 保護者かどうか（園児名の中で識別するためのラベル表示に使用）
    public let isGuardian: Bool
    /// 延滞中の貸出を持つかどうか
    public let isOverdue: Bool
    /// 家庭の枠がすべて使用中かどうか（貸出フローの利用者選択で
    /// 「タップしても借りられない」ことを事前に知らせるバッジに使用）
    public let hasNoOpenSlot: Bool

    public init(
        id: UUID, name: String, isGuardian: Bool, isOverdue: Bool, hasNoOpenSlot: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isGuardian = isGuardian
        self.isOverdue = isOverdue
        self.hasNoOpenSlot = hasNoOpenSlot
    }
}

/// 借用者一覧の組セクション
///
/// 既存画面（貸出管理の組別グルーピング・絵本一覧の五十音セクション）と
/// 同じ見た目の慣習に合わせ、一覧は組単位のセクションで区切る。
public struct BorrowerListSection: Identifiable, Equatable, Sendable {
    /// 組のID（未分類の場合は生成されたID）
    public let id: UUID
    /// セクション見出し（組名）
    public let title: String
    /// この組の借用者
    public let rows: [BorrowerRowDisplay]

    public init(id: UUID, title: String, rows: [BorrowerRowDisplay]) {
        self.id = id
        self.title = title
        self.rows = rows
    }
}

/// 借用者・利用者一覧のPresentation View（返却一覧と貸出の利用者選択が共用）
///
/// 利用者を名前のみで組セクション単位に一覧表示します。
/// 組チップの動作はホストする文脈に合わせて `SectionChipBehavior` で切り替えます
/// （返却一覧＝スクロールインデックス／貸出の利用者選択＝フィルタ）。
public struct BorrowerListView: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    /// 一覧の表示方式。返却の入口だけregular幅でコレクションにする。
    public enum LayoutStyle: Hashable {
        case list
        case adaptiveColumns
    }

    /// 組チップの動作モード
    ///
    /// - 返却一覧＝インデックス：探している名前がどこにいるか分からない画面では、
    ///   絞り込みで行が消えると「一覧に居ない」と勘違いするためスクロールジャンプにする
    /// - 貸出の利用者選択＝フィルタ：自分の組が分かっていて切り替えたい画面では、
    ///   一覧すべてを見せる必要がないため選んだ組だけに絞り込む
    public enum SectionChipBehavior {
        /// タップでその組セクションへスクロールする（行は消えない）
        case scrollIndex(scrollToTopTrigger: Int)
        /// タップでその組だけに絞り込む（再タップで解除）
        case filter(selection: Binding<UUID?>)
    }

    public let sections: [BorrowerListSection]
    public let layoutStyle: LayoutStyle
    /// 組チップの動作モード（既定はインデックス）
    public let chipBehavior: SectionChipBehavior
    /// 空状態のタイトル（ホストする文脈に合わせて差し替え可能）
    public let emptyStateTitle: String
    /// 空状態の説明文（ホストする文脈に合わせて差し替え可能）
    public let emptyStateDescription: String
    /// 「延滞のみ」フィルタのbinding（nilなら非表示。貸出フローの利用者選択では不要のため隠す）
    public let isOverdueOnly: Binding<Bool>?
    /// 階層へ進む場合だけ開示インジケータを表示する（Sheetを開く返却一覧では非表示）。
    public let showsDisclosureIndicator: Bool
    public let onSelect: (BorrowerRowDisplay) -> Void

    private enum Layout {
        static let chipSpacing: CGFloat = 8
        static let returnControlsTopPadding: CGFloat = 4
        static let returnControlsBottomPadding: CGFloat = 16
        static let rowVerticalPadding: CGFloat = 16
        /// 組ジャンプ時の着地アンカー。上端(y:0)より少し下げて、
        /// 先頭行の上にあるセクション見出しが視界に入るようにする
        static let sectionJumpAnchor = UnitPoint(x: 0.5, y: 0.06)
    }

    public init(
        sections: [BorrowerListSection],
        layoutStyle: LayoutStyle = .list,
        chipBehavior: SectionChipBehavior = .scrollIndex(scrollToTopTrigger: 0),
        emptyStateTitle: String = "現在、貸出中の利用者はいません",
        emptyStateDescription: String = "図書が貸し出されると、ここに名前が表示されます",
        isOverdueOnly: Binding<Bool>? = nil,
        showsDisclosureIndicator: Bool = true,
        onSelect: @escaping (BorrowerRowDisplay) -> Void
    ) {
        self.sections = sections
        self.layoutStyle = layoutStyle
        self.chipBehavior = chipBehavior
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateDescription = emptyStateDescription
        self.isOverdueOnly = isOverdueOnly
        self.showsDisclosureIndicator = showsDisclosureIndicator
        self.onSelect = onSelect
    }

    private var usesAdaptiveColumns: Bool {
        #if os(iOS)
            layoutStyle == .adaptiveColumns && horizontalSizeClass == .regular
        #else
            // sizeClassがない環境は従来の一覧を保つ。
            false
        #endif
    }

    /// 一覧に表示するセクション（フィルタモードで組が選ばれていればその組だけ）
    private var displayedSections: [BorrowerListSection] {
        if case .filter(let selection) = chipBehavior, let selectedId = selection.wrappedValue {
            sections.filter { $0.id == selectedId }
        } else {
            sections
        }
    }

    /// スクロールインデックスモードのトリガ値（`.onChange`用。フィルタモードでは実質未使用）
    private var scrollToTopTrigger: Int {
        if case .scrollIndex(let trigger) = chipBehavior {
            trigger
        } else {
            0
        }
    }

    /// チップのハイライト判定（フィルタモードで選択中の組のときだけtrue）
    private func isChipSelected(_ section: BorrowerListSection) -> Bool {
        if case .filter(let selection) = chipBehavior {
            selection.wrappedValue == section.id
        } else {
            false
        }
    }

    public var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                indexSection(proxy: proxy)

                // 空判定はフィルタ前の全体で行う（組の絞り込みによる一時的な空を
                // 「利用者がいない」空状態と誤認しないため）
                if sections.allSatisfy({ $0.rows.isEmpty }) {
                    emptyStateView
                } else if usesAdaptiveColumns {
                    BorrowerCollectionView(sections: displayedSections, onSelect: onSelect)
                } else {
                    borrowerListSection
                }
            }
            .background {
                LibrarySurfaceBackgroundView()
                    .ignoresSafeArea()
            }
            .onChange(of: scrollToTopTrigger) { _, _ in
                // 返却完了後の「次の利用者への引き継ぎ」：一覧を先頭へ戻す
                guard let firstSection = sections.first,
                    let firstRowId = firstSection.rows.first?.id
                else { return }
                let targetId = usesAdaptiveColumns ? firstSection.id : firstRowId
                let anchor = usesAdaptiveColumns ? UnitPoint.top : Layout.sectionJumpAnchor
                Task { @MainActor in
                    // Sheetを閉じる更新後のScrollViewに対して移動する。
                    await Task.yield()
                    withAnimation {
                        proxy.scrollTo(targetId, anchor: anchor)
                    }
                }
            }
        }
    }

    // MARK: - Private Views

    /// 組チップ（動作は `chipBehavior` に従う）＋「延滞のみ」フィルタ
    ///
    /// チップは借用者がいる組だけ表示する（押しても何も起きないチップを作らない）。
    private func indexSection(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: Layout.chipSpacing) {
            // iOS 27ベータにHStack内の横ScrollViewが幅0のまま描画されない不具合があるため、
            // ScrollViewを使わず素のHStackで並べる（絵本一覧のかなチップと同じ回避策）。
            // 収まらない幅（狭いSplit View等）ではかなチップと同じ思想でチップを出さない
            ViewThatFits(in: .horizontal) {
                chipRow(proxy: proxy)
                    .padding(.leading)
                Color.clear
                    .frame(width: 0, height: 0)
            }

            Spacer()

            if let isOverdueOnly {
                Toggle("延滞のみ", isOn: isOverdueOnly)
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .tint(isOverdueOnly.wrappedValue ? AppColor.overdue : .secondary)
                    .padding(.trailing)
            }
        }
        .padding(.top, isOverdueOnly != nil ? Layout.returnControlsTopPadding : 0)
        .padding(.bottom, isOverdueOnly != nil ? Layout.returnControlsBottomPadding : 0)
        .background {
            if isOverdueOnly != nil {
                Rectangle().fill(.background)
            }
        }
    }

    /// 組チップの並び（`ViewThatFits`の各候補から共通で参照する）
    private func chipRow(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: Layout.chipSpacing) {
            ForEach(sections) { section in
                Button(section.title) {
                    handleChipTap(section: section, proxy: proxy)
                }
                .buttonStyle(.bordered)
                .tint(isChipSelected(section) ? Color.accentColor : .secondary)
            }
        }
    }

    /// 組チップのタップ処理（インデックス＝スクロール／フィルタ＝絞り込みトグル）
    private func handleChipTap(section: BorrowerListSection, proxy: ScrollViewProxy) {
        switch chipBehavior {
        case .scrollIndex:
            // コレクションはLazyVStack直下の組IDを使い、未描画の組にも移動する。
            // Listでは従来どおり先頭の利用者IDを使う。
            // compactでは先頭行より少し上、regularでは組見出しを上端に置く。
            guard let targetRowId = section.rows.first?.id else { return }
            let targetId = usesAdaptiveColumns ? section.id : targetRowId
            withAnimation {
                proxy.scrollTo(
                    targetId, anchor: usesAdaptiveColumns ? .top : Layout.sectionJumpAnchor)
            }
        case .filter(let selection):
            selection.wrappedValue = selection.wrappedValue == section.id ? nil : section.id
        }
    }

    /// 空状態（タブは隠さず理由を説明する・HIG準拠）
    private var emptyStateView: some View {
        ContentUnavailableView(
            emptyStateTitle,
            systemImage: "books.vertical",
            description: Text(emptyStateDescription)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var borrowerListSection: some View {
        List {
            ForEach(displayedSections) { section in
                Section(
                    header: Text(section.title)
                        .font(.headline)
                        .foregroundStyle(AppColor.libraryTitle)
                ) {
                    ForEach(section.rows) { row in
                        Button {
                            onSelect(row)
                        } label: {
                            borrowerRow(row)
                        }
                        .buttonStyle(BorrowerCardButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 8, trailing: 20))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    /// 借用者1行：名前＋（保護者ラベル）＋（延滞マーク）
    private func borrowerRow(_ row: BorrowerRowDisplay) -> some View {
        HStack(alignment: .top, spacing: 16) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColor.libraryAction)
                .frame(width: 4, height: 40)
                .accessibilityHidden(true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Layout.chipSpacing) {
                    borrowerName(row)
                        .fixedSize(horizontal: true, vertical: false)
                    Spacer(minLength: 8)
                    BorrowerBadgesView(row: row)
                    borrowerDisclosureIndicator
                }

                VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                    HStack(spacing: Layout.chipSpacing) {
                        borrowerName(row)
                        Spacer(minLength: 8)
                        borrowerDisclosureIndicator
                    }
                    if row.isGuardian || row.hasNoOpenSlot || row.isOverdue {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: Layout.chipSpacing) { BorrowerBadgesView(row: row) }
                            VStack(alignment: .leading, spacing: Layout.chipSpacing) {
                                BorrowerBadgesView(row: row)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, Layout.rowVerticalPadding)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.borrowerCardSurface, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    AppColor.returnCardBorder,
                    lineWidth: colorSchemeContrast == .increased ? 2 : 1
                )
        }
        .shadow(color: .black.opacity(0.10), radius: 5, y: 2)
        .contentShape(Rectangle())
    }

    private func borrowerName(_ row: BorrowerRowDisplay) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("利用者")
                .font(.caption2)
                .foregroundStyle(AppColor.librarySecondaryText)
                .accessibilityHidden(true)
            Text(row.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColor.libraryTitle)
        }
    }

    @ViewBuilder
    private var borrowerDisclosureIndicator: some View {
        if showsDisclosureIndicator {
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.libraryAction)
                .accessibilityHidden(true)
        }
    }
}

private struct BorrowerCollectionView: View {
    @ScaledMetric(relativeTo: .title3) private var minimumCardWidth = Layout.minimumCardWidth

    let sections: [BorrowerListSection]
    let onSelect: (BorrowerRowDisplay) -> Void

    private enum Layout {
        static let minimumCardWidth: CGFloat = 240
        static let maximumColumns = 4
        static let spacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
    }

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = max(0, geometry.size.width - Layout.horizontalPadding * 2)
            let columnCount = max(
                1,
                min(
                    Layout.maximumColumns,
                    Int((availableWidth + Layout.spacing) / (minimumCardWidth + Layout.spacing))
                )
            )
            let columns = Array(
                repeating: GridItem(.flexible(), spacing: Layout.spacing, alignment: .top),
                count: columnCount
            )

            ScrollView {
                LazyVStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: Layout.spacing) {
                            Text(section.title)
                                .font(.headline)
                                .foregroundStyle(AppColor.libraryTitle)
                                .accessibilityAddTraits(.isHeader)

                            LazyVGrid(
                                columns: columns, alignment: .leading, spacing: Layout.spacing
                            ) {
                                ForEach(section.rows) { row in
                                    Button {
                                        onSelect(row)
                                    } label: {
                                        BorrowerCollectionCard(row: row)
                                    }
                                    .buttonStyle(BorrowerCardButtonStyle())
                                    .id(row.id)
                                }
                            }
                        }
                        .id(section.id)
                    }
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, Layout.spacing)
            }
        }
    }
}

private struct BorrowerCollectionCard: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @ScaledMetric(relativeTo: .title3) private var nameHeight = Layout.nameHeight
    @ScaledMetric(relativeTo: .caption) private var badgeHeight = Layout.badgeHeight

    let row: BorrowerRowDisplay

    private enum Layout {
        static let padding: CGFloat = 12
        static let spacing: CGFloat = 8
        static let cornerRadius: CGFloat = 14
        static let nameHeight: CGFloat = 50
        static let badgeHeight: CGFloat = 20
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            Text(row.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColor.libraryTitle)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: nameHeight, alignment: .topLeading)

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

private struct BorrowerCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

#Preview {
    @Previewable @State var isOverdueOnly = false

    let momo = ClassGroup(name: "もも組", ageGroup: AgeGroup.age(4), year: 2026)
    let bara = ClassGroup(name: "ばら組", ageGroup: AgeGroup.age(5), year: 2026)

    NavigationStack {
        BorrowerListView(
            sections: [
                BorrowerListSection(
                    id: momo.id, title: "もも組",
                    rows: [
                        BorrowerRowDisplay(
                            id: UUID(), name: "やまもと さくらこ", isGuardian: true, isOverdue: true,
                            hasNoOpenSlot: true),
                        BorrowerRowDisplay(
                            id: UUID(), name: "あおき はると", isGuardian: false, isOverdue: false),
                        BorrowerRowDisplay(
                            id: UUID(), name: "いとう さくら", isGuardian: false, isOverdue: false),
                        BorrowerRowDisplay(
                            id: UUID(), name: "かとう みなと", isGuardian: false, isOverdue: false,
                            hasNoOpenSlot: true),
                        BorrowerRowDisplay(
                            id: UUID(), name: "伊藤 由美子", isGuardian: true, isOverdue: false),
                    ]),
                BorrowerListSection(
                    id: bara.id, title: "ばら組",
                    rows: [
                        BorrowerRowDisplay(
                            id: UUID(), name: "うえだ そうた", isGuardian: false, isOverdue: true)
                    ]),
            ],
            isOverdueOnly: $isOverdueOnly,
            onSelect: { _ in }
        )
        .navigationTitle("返却")
    }
}

#Preview("空状態") {
    @Previewable @State var isOverdueOnly = false

    NavigationStack {
        BorrowerListView(
            sections: [],
            isOverdueOnly: $isOverdueOnly,
            onSelect: { _ in }
        )
        .navigationTitle("返却")
    }
}
