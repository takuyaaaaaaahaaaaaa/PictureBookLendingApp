import PictureBookLendingDomain
import SwiftUI

/// 組選択画面のプレゼンテーションビュー
public struct ClassGroupSelectionView: View {
    let classGroups: [ClassGroup]
    let onSelect: (ClassGroup) -> Void
    
    public init(
        classGroups: [ClassGroup],
        onSelect: @escaping (ClassGroup) -> Void
    ) {
        self.classGroups = classGroups
        self.onSelect = onSelect
    }
    
    public var body: some View {
        NavigationView {
            if classGroups.isEmpty {
                ContentUnavailableView(
                    "組が見つかりません",
                    systemImage: "person.2.slash",
                    description: Text("組を先に登録してください")
                )
            } else {
                List(classGroups) { classGroup in
                    ClassGroupRowView(classGroup: classGroup) {
                        onSelect(classGroup)
                    }
                }
                .navigationTitle("組を選択")
            }
        }
    }
}

/// 組一覧の行コンポーネント
private struct ClassGroupRowView: View {
    let classGroup: ClassGroup
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(classGroup.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\(classGroup.ageGroup) • \(classGroup.year)年度")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ClassGroupSelectionView(
        classGroups: [
            ClassGroup(name: "ひよこ組", ageGroup: AgeGroup.age(0), year: 2025),
            ClassGroup(name: "りす組", ageGroup: AgeGroup.age(1), year: 2025),
            ClassGroup(name: "うさぎ組", ageGroup: AgeGroup.age(2), year: 2025),
        ],
        onSelect: { _ in }
    )
}
