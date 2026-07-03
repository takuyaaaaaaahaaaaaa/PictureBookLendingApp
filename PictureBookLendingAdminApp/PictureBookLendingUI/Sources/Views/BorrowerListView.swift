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
    
    public init(id: UUID, name: String, isGuardian: Bool, isOverdue: Bool) {
        self.id = id
        self.name = name
        self.isGuardian = isGuardian
        self.isOverdue = isOverdue
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

/// 返却モードの借用者一覧のPresentation View
///
/// 現在貸出中の利用者（園児・保護者の両方）を名前のみで組セクション単位に一覧表示します。
/// 組フィルタチップと「延滞のみ」フィルタを備え、先生の俯瞰を兼ねます。
public struct BorrowerListView: View {
    public let sections: [BorrowerListSection]
    public let classGroups: [ClassGroup]
    @Binding public var selectedClassGroup: ClassGroup?
    @Binding public var isOverdueOnly: Bool
    public let onSelect: (BorrowerRowDisplay) -> Void
    
    private enum Layout {
        static let chipSpacing: CGFloat = 8
        static let rowVerticalPadding: CGFloat = 12
        static let badgePaddingH: CGFloat = 8
        static let badgePaddingV: CGFloat = 3
    }
    
    public init(
        sections: [BorrowerListSection],
        classGroups: [ClassGroup],
        selectedClassGroup: Binding<ClassGroup?>,
        isOverdueOnly: Binding<Bool>,
        onSelect: @escaping (BorrowerRowDisplay) -> Void
    ) {
        self.sections = sections
        self.classGroups = classGroups
        self._selectedClassGroup = selectedClassGroup
        self._isOverdueOnly = isOverdueOnly
        self.onSelect = onSelect
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Layout.chipSpacing) {
            filterSection
            
            if sections.allSatisfy({ $0.rows.isEmpty }) {
                emptyStateView
            } else {
                borrowerListSection
            }
        }
    }
    
    // MARK: - Private Views
    
    /// 組フィルタチップ＋「延滞のみ」フィルタ
    private var filterSection: some View {
        HStack(spacing: Layout.chipSpacing) {
            ScrollView(.horizontal) {
                HStack(spacing: Layout.chipSpacing) {
                    ForEach(classGroups) { group in
                        Button(group.name) {
                            // 未選択なら選択、選択中なら解除
                            if selectedClassGroup == group {
                                selectedClassGroup = nil
                            } else {
                                selectedClassGroup = group
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedClassGroup == group ? .accentColor : .secondary)
                    }
                }
                .padding(.leading)
            }
            
            Spacer()
            
            Toggle("延滞のみ", isOn: $isOverdueOnly)
                .toggleStyle(.button)
                .buttonStyle(.bordered)
                .tint(isOverdueOnly ? .red : .secondary)
                .padding(.trailing)
        }
    }
    
    /// 空状態（タブは隠さず理由を説明する・HIG準拠）
    private var emptyStateView: some View {
        ContentUnavailableView(
            "現在、貸出中の利用者はいません",
            systemImage: "books.vertical",
            description: Text("図書が貸し出されると、ここに名前が表示されます")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var borrowerListSection: some View {
        List {
            ForEach(sections) { section in
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
    @Previewable @State var selectedClassGroup: ClassGroup? = nil
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
            classGroups: [momo, bara],
            selectedClassGroup: $selectedClassGroup,
            isOverdueOnly: $isOverdueOnly,
            onSelect: { _ in }
        )
        .navigationTitle("返却")
    }
}

#Preview("空状態") {
    @Previewable @State var selectedClassGroup: ClassGroup? = nil
    @Previewable @State var isOverdueOnly = false
    
    NavigationStack {
        BorrowerListView(
            sections: [],
            classGroups: [],
            selectedClassGroup: $selectedClassGroup,
            isOverdueOnly: $isOverdueOnly,
            onSelect: { _ in }
        )
        .navigationTitle("返却")
    }
}
