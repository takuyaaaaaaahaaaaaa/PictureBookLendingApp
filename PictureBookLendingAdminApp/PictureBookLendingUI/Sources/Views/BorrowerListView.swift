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
public struct BorrowerListView<Header: View>: View {
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
    private let header: Header
    private var usesControlsBar = true

    public init(
        sections: [BorrowerListSection],
        layoutStyle: LayoutStyle = .list,
        chipBehavior: SectionChipBehavior = .scrollIndex(scrollToTopTrigger: 0),
        emptyStateTitle: String = "現在、貸出中の利用者はいません",
        emptyStateDescription: String = "図書が貸し出されると、ここに名前が表示されます",
        isOverdueOnly: Binding<Bool>? = nil,
        showsDisclosureIndicator: Bool = true,
        onSelect: @escaping (BorrowerRowDisplay) -> Void,
        @ViewBuilder header: () -> Header
    ) {
        self.sections = sections
        self.layoutStyle = layoutStyle
        self.chipBehavior = chipBehavior
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateDescription = emptyStateDescription
        self.isOverdueOnly = isOverdueOnly
        self.showsDisclosureIndicator = showsDisclosureIndicator
        self.onSelect = onSelect
        self.header = header()
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
            VStack(alignment: .leading, spacing: BorrowerListLayout.chipSpacing) {
                if !usesControlsBar {
                    indexSection(proxy: proxy)
                }

                // 空判定はフィルタ前の全体で行う（組の絞り込みによる一時的な空を
                // 「利用者がいない」空状態と誤認しないため）
                if sections.allSatisfy({ $0.rows.isEmpty }) {
                    emptyStateView
                } else if usesAdaptiveColumns {
                    BorrowerCollectionView(
                        sections: displayedSections,
                        showsDisclosureIndicator: showsDisclosureIndicator,
                        onSelect: onSelect)
                } else {
                    borrowerListSection
                }
            }
            .modifier(
                BorrowerControlsBar(
                    content: VStack(spacing: 0) {
                        if usesControlsBar {
                            header
                            indexSection(proxy: proxy)
                        }
                    })
            )
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
                let anchor =
                    usesAdaptiveColumns ? UnitPoint.top : BorrowerListLayout.sectionJumpAnchor
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
        HStack(spacing: BorrowerListLayout.chipSpacing) {
            // iOS 27ベータにHStack内の横ScrollViewが幅0のまま描画されない不具合があるため、
            // ScrollViewを使わず素のHStackで並べる（絵本一覧のかなチップと同じ回避策）。
            // 収まらない幅（狭いSplit View等）ではかなチップと同じ思想でチップを出さない
            ViewThatFits(in: .horizontal) {
                chipRow(proxy: proxy)
                    .fixedSize(horizontal: true, vertical: false)
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
        .padding(.top, isOverdueOnly != nil ? BorrowerListLayout.returnControlsTopPadding : 0)
        .padding(.bottom, isOverdueOnly != nil ? BorrowerListLayout.returnControlsBottomPadding : 0)
    }

    /// 組チップの並び（`ViewThatFits`の各候補から共通で参照する）
    private func chipRow(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: BorrowerListLayout.chipSpacing) {
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
                    targetId,
                    anchor: usesAdaptiveColumns ? .top : BorrowerListLayout.sectionJumpAnchor)
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
                            BorrowerCardView(
                                row: row, showsDisclosureIndicator: showsDisclosureIndicator)
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

}

private enum BorrowerListLayout {
    static let chipSpacing: CGFloat = 8
    static let returnControlsTopPadding: CGFloat = 4
    static let returnControlsBottomPadding: CGFloat = 16
    /// 組ジャンプ時の着地アンカー。上端(y:0)より少し下げて、
    /// 先頭行の上にあるセクション見出しが視界に入るようにする
    static let sectionJumpAnchor = UnitPoint(x: 0.5, y: 0.06)
}

extension BorrowerListView where Header == EmptyView {
    /// 検索ヘッダを持たない貸出シートなどは、従来の組チップ配置を保つ。
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
        self.init(
            sections: sections,
            layoutStyle: layoutStyle,
            chipBehavior: chipBehavior,
            emptyStateTitle: emptyStateTitle,
            emptyStateDescription: emptyStateDescription,
            isOverdueOnly: isOverdueOnly,
            showsDisclosureIndicator: showsDisclosureIndicator,
            onSelect: onSelect,
            header: { EmptyView() }
        )
        usesControlsBar = false
    }
}

/// UIパッケージの最低OSを維持しつつ、標準のスクロール端効果をバーへ延長する。
private struct BorrowerControlsBar<BarContent: View>: ViewModifier {
    let content: BarContent

    @ViewBuilder
    func body(content base: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
            base.safeAreaBar(edge: .top, spacing: 0) { content }
        } else {
            base.safeAreaInset(edge: .top, spacing: 0) { content }
        }
    }
}

private struct BorrowerCollectionView: View {
    @ScaledMetric(relativeTo: .title3) private var minimumCardWidth = Layout.minimumCardWidth

    let sections: [BorrowerListSection]
    let showsDisclosureIndicator: Bool
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
                                        BorrowerCardView(
                                            row: row,
                                            showsDisclosureIndicator: showsDisclosureIndicator)
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
                            id: UUID(), name: "やまもと さくらこ", isGuardian: true, isOverdue: true),
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
