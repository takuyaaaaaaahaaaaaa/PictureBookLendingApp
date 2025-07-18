import PictureBookLendingDomain
import SwiftUI

/// 絵本フォームの操作モード
public enum BookFormMode {
    case add
    case edit(Book)
}

/// 利用者フォームの操作モード
public enum UserFormMode {
    case add
    case edit(User)
}

/// 詳細表示用の行コンポーネント
public struct DetailRow: View {
    let label: String
    let value: String
    
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    public var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .textSelection(.enabled)
        }
    }
}

/// 編集可能な詳細表示用の行コンポーネント
public struct EditableDetailRow: View {
    let label: String
    @Binding var value: String
    public init(
        label: String,
        value: Binding<String>,
    ) {
        self.label = label
        self._value = value
    }
    
    public var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            HStack {
                TextField("", text: $value)
                    .foregroundStyle(value.isEmpty ? .secondary : .primary)
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// 選択肢付きの編集可能な詳細表示用の行コンポーネント
public struct EditableDetailRowWithSelection<SelectionValue: Hashable>: View {
    let label: String
    @Binding var selectedValue: SelectionValue
    let options: [SelectionValue]
    let displayText: (SelectionValue) -> String
    let onSelectionChanged: (SelectionValue) -> Void
    
    @State private var isShowingSelection = false
    
    public init(
        label: String,
        selectedValue: Binding<SelectionValue>,
        options: [SelectionValue],
        displayText: @escaping (SelectionValue) -> String,
        onSelectionChanged: @escaping (SelectionValue) -> Void = { _ in }
    ) {
        self.label = label
        self._selectedValue = selectedValue
        self.options = options
        self.displayText = displayText
        self.onSelectionChanged = onSelectionChanged
    }
    
    public var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            
            Button(action: { isShowingSelection = true }) {
                HStack {
                    Text(displayText(selectedValue))
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .confirmationDialog(label, isPresented: $isShowingSelection) {
                ForEach(options, id: \.self) { option in
                    Button(displayText(option)) {
                        selectedValue = option
                        onSelectionChanged(option)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}
