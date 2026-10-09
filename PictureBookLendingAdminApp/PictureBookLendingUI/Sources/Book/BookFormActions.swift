import SwiftUI

/// Shared navigation actions; the screen hosting the form owns this toolbar.
public struct BookFormActions: ToolbarContent {
    let isEditMode: Bool
    let canSave: Bool
    let isEnabled: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    public init(
        isEditMode: Bool, canSave: Bool, isEnabled: Bool = true,
        onSave: @escaping () -> Void, onCancel: @escaping () -> Void
    ) {
        self.isEditMode = isEditMode
        self.canSave = canSave
        self.isEnabled = isEnabled
        self.onSave = onSave
        self.onCancel = onCancel
    }

    public var body: some ToolbarContent {
        ToolbarItem(id: "bookForm.cancel", placement: .cancellationAction) {
            Button("キャンセル", role: .cancel, action: onCancel)
                .accessibilityIdentifier("bookForm.cancel")
                .disabled(!isEnabled)
        }
        ToolbarItem(id: "bookForm.save", placement: .confirmationAction) {
            Group {
                if #available(iOS 26, macOS 26, *) {
                    Button(role: .confirm, action: onSave)
                } else {
                    Button(isEditMode ? "保存" : "追加", action: onSave)
                }
            }
            .accessibilityIdentifier("bookForm.save")
            .disabled(!isEnabled || !canSave)
        }
    }
}
