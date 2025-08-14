import PictureBookLendingDomain
import SwiftUI

/// 組一覧のPresentation View
///
/// 組の一覧表示とユーザーインタラクションを担当します。
/// データ取得やビジネスロジックはContainer Viewに委譲します。
public struct ClassGroupListView: View {
    let classGroups: [ClassGroup]
    let getUserCount: (UUID) -> Int
    let onAdd: () -> Void
    let onEdit: (ClassGroup) -> Void
    let onDelete: (IndexSet) -> Void
    
    public init(
        classGroups: [ClassGroup],
        getUserCount: @escaping (UUID) -> Int,
        onAdd: @escaping () -> Void,
        onEdit: @escaping (ClassGroup) -> Void,
        onDelete: @escaping (IndexSet) -> Void
    ) {
        self.classGroups = classGroups
        self.getUserCount = getUserCount
        self.onAdd = onAdd
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
                        userCount: getUserCount(classGroup.id)
                    ) {
                        onEdit(classGroup)
                    }
                }
                .onDelete(perform: onDelete)
            }
        }
    }
}

/// 組一覧の行表示コンポーネント
public struct ClassGroupListRowView: View {
    let classGroup: ClassGroup
    let userCount: Int
    let onTap: () -> Void
    
    public init(classGroup: ClassGroup, userCount: Int, onTap: @escaping () -> Void) {
        self.classGroup = classGroup
        self.userCount = userCount
        self.onTap = onTap
    }
    
    public var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(classGroup.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    let ageGroupText = Text("\(classGroup.ageGroup)歳児 ")
                    let yearText = Text("\(classGroup.year, format: .number.grouping(.never))年度")
                    let userCountText = Text(" • \(userCount)人")
                    Text("\(ageGroupText)(\(yearText))\(userCountText)")
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
                ClassGroup(name: "ひまわり組", ageGroup: 3, year: 2024),
                ClassGroup(name: "たんぽぽ組", ageGroup: 4, year: 2024),
                ClassGroup(name: "さくら組", ageGroup: 5, year: 2024),
            ],
            getUserCount: { _ in 8 },
            onAdd: {},
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
            getUserCount: { _ in 0 },
            onAdd: {},
            onEdit: { _ in },
            onDelete: { _ in }
        )
        .navigationTitle("組管理")
    }
}

#Preview("組の行") {
    List {
        ClassGroupListRowView(
            classGroup: ClassGroup(name: "ひまわり組", ageGroup: 3, year: 2024), userCount: 8
        ) {}
        ClassGroupListRowView(
            classGroup: ClassGroup(name: "たんぽぽ組", ageGroup: 4, year: 2024), userCount: 12
        ) {}
    }
}
