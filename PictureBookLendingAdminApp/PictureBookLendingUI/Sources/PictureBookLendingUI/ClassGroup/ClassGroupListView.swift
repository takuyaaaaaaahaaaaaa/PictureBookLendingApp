import PictureBookLendingDomain
import SwiftUI

/// 組一覧のPresentation View
///
/// 組の一覧表示とユーザーインタラクションを担当します。
/// データ取得やビジネスロジックはContainer Viewに委譲します。
public struct ClassGroupListView: View {
    let classGroups: [ClassGroup]
    let getChildCount: (UUID) -> Int
    let getGuardianCount: (UUID) -> Int
    let isEditMode: Bool
    let onAdd: () -> Void
    let onSelect: (ClassGroup) -> Void
    let onEdit: (ClassGroup) -> Void
    let onDelete: (IndexSet) -> Void
    
    public init(
        classGroups: [ClassGroup],
        getChildCount: @escaping (UUID) -> Int,
        getGuardianCount: @escaping (UUID) -> Int,
        isEditMode: Bool = false,
        onAdd: @escaping () -> Void,
        onSelect: @escaping (ClassGroup) -> Void,
        onEdit: @escaping (ClassGroup) -> Void,
        onDelete: @escaping (IndexSet) -> Void
    ) {
        self.classGroups = classGroups
        self.getChildCount = getChildCount
        self.getGuardianCount = getGuardianCount
        self.isEditMode = isEditMode
        self.onAdd = onAdd
        self.onSelect = onSelect
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    public var body: some View {
        if classGroups.isEmpty {
            ContentUnavailableView(
                "組が登録されていません",
                systemImage: "person.3",
                description: Text("組を追加して利用者を管理しましょう")
            )
        } else {
            List {
                ForEach(classGroups) { classGroup in
                    ClassGroupListRowView(
                        classGroup: classGroup,
                        childCount: getChildCount(classGroup.id),
                        guardianCount: getGuardianCount(classGroup.id)
                    ) {
                        if isEditMode {
                            onEdit(classGroup)
                        } else {
                            onSelect(classGroup)
                        }
                    }
                }
                .onDelete(perform: isEditMode ? onDelete : nil)
            }
        }
    }
}

/// 組一覧の行表示コンポーネント
public struct ClassGroupListRowView: View {
    let classGroup: ClassGroup
    let childCount: Int
    let guardianCount: Int
    let onTap: () -> Void
    
    public init(
        classGroup: ClassGroup, childCount: Int, guardianCount: Int, onTap: @escaping () -> Void
    ) {
        self.classGroup = classGroup
        self.childCount = childCount
        self.guardianCount = guardianCount
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(classGroup.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    let ageGroupText = Text("\(classGroup.ageGroup.displayText) ")
                    let yearText = Text("\(classGroup.year, format: .number.grouping(.never))年度")
                    let childCountText = Text(" • 園児\(childCount)人")
                    let guardianCountText = Text(" • 保護者\(guardianCount)人")
                    Text("\(ageGroupText)(\(yearText))\(childCountText)\(guardianCountText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview("組一覧") {
    NavigationStack {
        ClassGroupListView(
            classGroups: [
                ClassGroup(name: "ひまわり組", ageGroup: AgeGroup.age(3), year: 2024),
                ClassGroup(name: "たんぽぽ組", ageGroup: AgeGroup.age(4), year: 2024),
                ClassGroup(name: "さくら組", ageGroup: AgeGroup.age(5), year: 2024),
            ],
            getChildCount: { _ in 8 },
            getGuardianCount: { _ in 16 },
            onAdd: {},
            onSelect: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )
        .navigationTitle("組管理")
    }
}

#Preview("空の組一覧") {
    NavigationStack {
        ClassGroupListView(
            classGroups: [],
            getChildCount: { _ in 0 },
            getGuardianCount: { _ in 0 },
            onAdd: {},
            onSelect: { _ in },
            onEdit: { _ in },
            onDelete: { _ in }
        )
        .navigationTitle("組管理")
    }
}

#Preview("組の行") {
    List {
        ClassGroupListRowView(
            classGroup: ClassGroup(
                name: "ひまわり組", ageGroup: AgeGroup.age(3), year: 2024),
            childCount: 8, guardianCount: 16
        ) {}
        ClassGroupListRowView(
            classGroup: ClassGroup(
                name: "たんぽぽ組", ageGroup: AgeGroup.age(4), year: 2024),
            childCount: 12, guardianCount: 24
        ) {}
    }
}
