import PictureBookLendingDomain
import SwiftUI

/// 絵本フォームのPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert等の
/// 画面制御はContainer Viewに委譲します。
public struct BookFormView: View {
    @Binding var book: Book
    let mode: BookFormMode
    let onSave: () -> Void
    let onCancel: () -> Void
    
    public init(
        book: Binding<Book>,
        mode: BookFormMode,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._book = book
        self.mode = mode
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    public var body: some View {
        Form {
            Section(header: Text("基本情報（*は必須）")) {
                TextField("タイトル *", text: $book.title)
                TextField("著者 *", text: $book.author)
                TextField(
                    "管理番号（例: あ13）",
                    text: Binding(
                        get: { book.managementNumber ?? "" },
                        set: { book.managementNumber = $0.isEmpty ? nil : $0 }
                    ))
            }
            
            Section(header: Text("詳細情報（任意）")) {
                TextField(
                    "ISBN-13",
                    text: Binding(
                        get: { book.isbn13 ?? "" },
                        set: { book.isbn13 = $0.isEmpty ? nil : $0 }
                    ))
                TextField(
                    "出版社",
                    text: Binding(
                        get: { book.publisher ?? "" },
                        set: { book.publisher = $0.isEmpty ? nil : $0 }
                    ))
                TextField(
                    "出版日",
                    text: Binding(
                        get: { book.publishedDate ?? "" },
                        set: { book.publishedDate = $0.isEmpty ? nil : $0 }
                    ))
            }
            
            Section(header: Text("その他（任意）")) {
                HStack {
                    Text("対象読者")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("対象読者", selection: $book.targetAge) {
                        Text("未選択").tag(nil as Const.TargetAudience?)
                        ForEach(Const.TargetAudience.sortedCases, id: \.self) { audience in
                            Text(audience.displayText).tag(audience as Const.TargetAudience?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                TextField(
                    "ページ数",
                    text: Binding(
                        get: { book.pageCount.map(String.init) ?? "" },
                        set: { newValue in
                            if newValue.isEmpty {
                                book.pageCount = nil
                            } else if let intValue = Int(newValue), intValue >= 0 {
                                book.pageCount = intValue
                            }
                        }
                    )
                )
                #if os(iOS)
                    .keyboardType(.numberPad)
                #endif
            }
            
            Section(header: Text("説明（任意）")) {
                TextField(
                    "絵本の説明・あらすじ",
                    text: Binding(
                        get: { book.description ?? "" },
                        set: { book.description = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical
                )
                .lineLimit(3...6)
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
        !book.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !book.author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    @Previewable @State var sampleBook = Book(
        title: "サンプル本",
        author: "著者名",
        isbn13: "9784001234567",
        publisher: "サンプル出版",
        publishedDate: "2023-01-01",
        description: "これはサンプルの絵本です。",
        targetAge: .toddler,
        pageCount: 32,
        categories: ["絵本"],
        managementNumber: "あ13"
    )
    
    NavigationStack {
        BookFormView(
            book: $sampleBook,
            mode: .add,
            onSave: {},
            onCancel: {}
        )
        .navigationTitle("絵本を追加")
    }
}
