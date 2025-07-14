import SwiftUI
import PictureBookLendingDomain

/**
 * 利用者フォームのPresentation View
 *
 * 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
 * 画面制御はContainer Viewに委譲します。
 */
public struct UserFormView: View {
    let mode: UserFormMode
    let name: Binding<String>
    let group: Binding<String>
    let isValidInput: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    public init(
        mode: UserFormMode,
        name: Binding<String>,
        group: Binding<String>,
        isValidInput: Bool,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.mode = mode
        self.name = name
        self.group = group
        self.isValidInput = isValidInput
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    public var body: some View {
        Form {
            Section(header: Text("利用者情報")) {
                TextField("名前", text: name)
                TextField("グループ（クラスなど）", text: group)
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
    let sampleUser = User(name: "山田太郎", group: "1年2組")
    
    NavigationStack {
        UserFormView(
            mode: .edit(sampleUser),
            name: .constant("山田太郎"),
            group: .constant("1年2組"),
            isValidInput: true,
            onSave: {},
            onCancel: {}
        )
        .navigationTitle("利用者情報を編集")
    }
}