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
    /// 組チップの動作モード
    ///
    /// - 返却一覧＝インデックス：探している名前がどこにいるか分からない画面では、
    ///   絞り込みで行が消えると「一覧に居ない」と勘違いするためスクロールジャンプにする
    /// - 貸出の利用者選択＝フィルタ：自分の組が分かっていて切り替えたい画面では、
    ///   一覧すべてを見せる必要がないため選んだ組だけに絞り込む
    public enum SectionChipBehavior: Hashable {
        /// タップでその組セクションへスクロールする（行は消えない）
        case scrollIndex
        /// タップでその組だけに絞り込む（再タップで解除）
        case filter
    }
    
    public let sections: [BorrowerListSection]
    /// 値が変わると一覧をトップへスクロールする（返却完了後、次の利用者のために初期位置へ戻す）
    public let scrollToTopTrigger: Int
    /// 「延滞のみ」フィルタを表示するかどうか（貸出フローの利用者選択では不要のため隠す）
    public let showsOverdueFilter: Bool
    /// 空状態のタイトル（ホストする文脈に合わせて差し替え可能）
    public let emptyStateTitle: String
    /// 空状態の説明文（ホストする文脈に合わせて差し替え可能）
    public let emptyStateDescription: String
    /// 組チップの動作モード（既定はインデックス）
    public let chipBehavior: SectionChipBehavior
    /// フィルタモードで選択中の組ID（nilなら全組を表示）
    @Binding public var selectedSectionId: UUID?
    @Binding public var isOverdueOnly: Bool
    public let onSelect: (BorrowerRowDisplay) -> Void
    
    private enum Layout {
        static let chipSpacing: CGFloat = 8
        static let rowVerticalPadding: CGFloat = 12
        static let badgePaddingH: CGFloat = 8
        static let badgePaddingV: CGFloat = 3
        /// 組ジャンプ時の着地アンカー。上端(y:0)より少し下げて、
        /// 先頭行の上にあるセクション見出しが視界に入るようにする
        static let sectionJumpAnchor = UnitPoint(x: 0.5, y: 0.06)
    }
    
    public init(
        sections: [BorrowerListSection],
        scrollToTopTrigger: Int = 0,
        showsOverdueFilter: Bool = true,
        emptyStateTitle: String = "現在、貸出中の利用者はいません",
        emptyStateDescription: String = "図書が貸し出されると、ここに名前が表示されます",
        chipBehavior: SectionChipBehavior = .scrollIndex,
        selectedSectionId: Binding<UUID?> = .constant(nil),
        isOverdueOnly: Binding<Bool>,
        onSelect: @escaping (BorrowerRowDisplay) -> Void
    ) {
        self.sections = sections
        self.scrollToTopTrigger = scrollToTopTrigger
        self.showsOverdueFilter = showsOverdueFilter
        self.emptyStateTitle = emptyStateTitle
        self.emptyStateDescription = emptyStateDescription
        self.chipBehavior = chipBehavior
        self._selectedSectionId = selectedSectionId
        self._isOverdueOnly = isOverdueOnly
        self.onSelect = onSelect
    }
    
    /// 一覧に表示するセクション（フィルタモードで組が選ばれていればその組だけ）
    private var displayedSections: [BorrowerListSection] {
        if chipBehavior == .filter, let selectedSectionId {
            sections.filter { $0.id == selectedSectionId }
        } else {
            sections
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
                } else {
                    borrowerListSection
                }
            }
            .onChange(of: scrollToTopTrigger) { _, _ in
                // 返却完了後の「次の利用者への引き継ぎ」：一覧を先頭へ戻す
                guard let firstRowId = sections.first?.rows.first?.id else { return }
                withAnimation {
                    proxy.scrollTo(firstRowId, anchor: Layout.sectionJumpAnchor)
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
            ScrollView(.horizontal) {
                HStack(spacing: Layout.chipSpacing) {
                    ForEach(sections) { section in
                        Button(section.title) {
                            handleChipTap(section: section, proxy: proxy)
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedSectionId == section.id ? Color.accentColor : .secondary)
                    }
                }
                .padding(.leading)
            }
            
            Spacer()
            
            if showsOverdueFilter {
                Toggle("延滞のみ", isOn: $isOverdueOnly)
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .tint(isOverdueOnly ? .red : .secondary)
                    .padding(.trailing)
            }
        }
    }
    
    /// 組チップのタップ処理（インデックス＝スクロール／フィルタ＝絞り込みトグル）
    private func handleChipTap(section: BorrowerListSection, proxy: ScrollViewProxy) {
        switch chipBehavior {
        case .scrollIndex:
            // Listの遅延描画では見出しのIDがscrollToに解決されないため、
            // 確実に登録される先頭行のIDへスクロールする。
            // アンカーを上端より少し下げ、行の上にある組タイトルまで見せる
            guard let targetRowId = section.rows.first?.id else { return }
            withAnimation {
                proxy.scrollTo(targetRowId, anchor: Layout.sectionJumpAnchor)
            }
        case .filter:
            selectedSectionId = selectedSectionId == section.id ? nil : section.id
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
                Section(header: Text(section.title)) {
                    ForEach(section.rows) { row in
                        Button {
                            onSelect(row)
                        } label: {
                            borrowerRow(row)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    /// 借用者1行：名前＋（保護者ラベル）＋（延滞マーク）
    private func borrowerRow(_ row: BorrowerRowDisplay) -> some View {
        HStack(spacing: Layout.chipSpacing) {
            Text(row.name)
                .font(.title3)
            
            if row.isGuardian {
                Text("保護者")
                    .font(.caption)
                    .padding(.horizontal, Layout.badgePaddingH)
                    .padding(.vertical, Layout.badgePaddingV)
                    .background(.quaternary, in: Capsule())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if row.hasNoOpenSlot {
                // グレー＝「いまは借りられない」の色（図書一覧の貸出中ボタンと同じ言葉遣い）。
                // 行はタップ可能なままにし、家庭の画面で枠が使用中である理由を見せる
                Text("空き枠なし")
                    .font(.caption.bold())
                    .padding(.horizontal, Layout.badgePaddingH)
                    .padding(.vertical, Layout.badgePaddingV)
                    .background(.gray, in: Capsule())
                    .foregroundStyle(.white)
            }
            
            if row.isOverdue {
                Text("延滞")
                    .font(.caption.bold())
                    .padding(.horizontal, Layout.badgePaddingH)
                    .padding(.vertical, Layout.badgePaddingV)
                    .background(.red, in: Capsule())
                    .foregroundStyle(.white)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Layout.rowVerticalPadding)
        .contentShape(Rectangle())
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
                            id: UUID(), name: "あおき はると", isGuardian: false, isOverdue: false),
                        BorrowerRowDisplay(
                            id: UUID(), name: "いとう さくら", isGuardian: false, isOverdue: false),
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
