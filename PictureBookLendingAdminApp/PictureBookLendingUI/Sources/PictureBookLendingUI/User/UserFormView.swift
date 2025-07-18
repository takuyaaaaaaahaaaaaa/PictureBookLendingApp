import PictureBookLendingDomain
import SwiftUI

/// 利用者フォームのPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct UserFormView: View {
    let mode: UserFormMode
    let name: Binding<String>
    let classGroup: Binding<ClassGroup?>
    let classGroups: [ClassGroup]
    
    public init(
        mode: UserFormMode,
        name: Binding<String>,
        classGroup: Binding<ClassGroup?>,
        classGroups: [ClassGroup]
    ) {
        self.mode = mode
        self.name = name
        self.classGroup = classGroup
        self.classGroups = classGroups
    }
    
    public var body: some View {
        Form {
            Section(header: Text("利用者情報")) {
                TextField("名前", text: name)
                Picker("組", selection: classGroup) {
                    ForEach(classGroups) { group in
                        Text(group.name).tag(group)
                    }
                }
            }
        }
    }
    
    private var isEditMode: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }
}

#Preview {
    let sampleUser = User(name: "山田太郎", classGroupId: UUID())
    let classGroups = [
        ClassGroup(name: "きく", ageGroup: 1, year: 2025),
        ClassGroup(name: "ひまわり", ageGroup: 2, year: 2025),
    ]
    
    NavigationStack {
        UserFormView(
            mode: .edit(sampleUser),
            name: .constant("山田太郎"),
            classGroup: .constant(classGroups[1]),
            classGroups: classGroups
        )
        .navigationTitle("利用者情報を編集")
    }
}
