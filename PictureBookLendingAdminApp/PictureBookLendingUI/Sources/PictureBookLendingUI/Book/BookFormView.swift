import PictureBookLendingDomain
import SwiftUI

/// 絵本フォームのPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert等の
/// 画面制御はContainer Viewに委譲します。
public struct BookFormView: View {
    @Binding var title: String
    @Binding var author: String
    @Binding var managementNumber: String
    let mode: BookFormMode
    let onSave: () -> Void
    let onCancel: () -> Void
    
    public init(
        title: Binding<String>,
        author: Binding<String>,
        managementNumber: Binding<String>,
        mode: BookFormMode,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._title = title
        self._author = author
        self._managementNumber = managementNumber
        self.mode = mode
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    public var body: some View {
        Form {
            Section(header: Text("絵本情報")) {
                TextField("タイトル", text: $title)
                TextField("著者", text: $author)
                TextField("管理番号（例: あ13）", text: $managementNumber)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    onCancel()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditMode ? "保存" : "追加") {
                    onSave()
                }
                .disabled(!isValidInput)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isEditMode: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }
    
    private var isValidInput: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    NavigationStack {
        BookFormView(
            title: .constant("サンプル本"),
            author: .constant("著者名"),
            managementNumber: .constant("あ13"),
            mode: .add,
            onSave: {},
            onCancel: {}
        )
        .navigationTitle("絵本を追加")
    }
}
