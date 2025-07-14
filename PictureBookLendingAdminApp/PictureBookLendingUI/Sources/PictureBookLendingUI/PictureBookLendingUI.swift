import SwiftUI
import PictureBookLendingDomain

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

/**
 * 詳細表示用の行コンポーネント
 */
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
