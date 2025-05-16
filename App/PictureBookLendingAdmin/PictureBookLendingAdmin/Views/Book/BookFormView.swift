import SwiftUI
import PictureBookLendingCore

/// 絵本フォームの操作モード
enum BookFormMode {
    case add
    case edit(Book)
}

/**
 * 絵本情報入力フォームビュー
 *
 * 絵本の新規登録と既存絵本の編集に使用できるフォームビューです。
 */
struct BookFormView: View {
    @Environment(\.bookModel) private var bookModel
    @Environment(\.dismiss) private var dismiss
    
    // フォームのモード（追加/編集）
    let mode: BookFormMode
    
    // フォーム入力値
    @State private var title: String = ""
    @State private var author: String = ""
    
    // エラー表示用
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("絵本情報")) {
                    TextField("タイトル", text: $title)
                    TextField("著者", text: $author)
                }
            }
            .navigationTitle(isEditMode ? "絵本を編集" : "絵本を追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "保存" : "追加") {
                        saveBook()
                    }
                    .disabled(!isValidInput)
                }
            }
            .onAppear {
                // 編集モードの場合、初期値をセット
                if case .edit(let book) = mode {
                    title = book.title
                    author = book.author
                }
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // 編集モードかどうか
    private var isEditMode: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }
    
    // 入力値が有効かどうか
    private var isValidInput: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // 絵本の保存/更新処理
    private func saveBook() {
        guard let bookModel = bookModel else {
            showError("モデルが利用できません")
            return
        }
        
        do {
            switch mode {
            case .add:
                let newBook = Book(title: title, author: author)
                _ = try bookModel.registerBook(newBook)
                
            case .edit(let book):
                let updatedBook = Book(
                    id: book.id,
                    title: title,
                    author: author
                )
                _ = try bookModel.updateBook(updatedBook)
            }
            
            dismiss()
        } catch {
            showError("保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // エラー表示
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    BookFormView(mode: .add)
}