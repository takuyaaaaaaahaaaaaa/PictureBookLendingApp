import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 絵本フォームのContainer View
///
/// ビジネスロジック、状態管理、データ永続化を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct BookFormContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(\.dismiss) private var dismiss
    
    let mode: BookFormMode
    var onSave: ((Book) -> Void)? = nil
    
    @State private var book: Book
    @State private var alertState = AlertState()
    
    init(mode: BookFormMode, onSave: ((Book) -> Void)? = nil) {
        self.mode = mode
        self.onSave = onSave
        
        // 初期値を設定
        switch mode {
        case .add:
            self._book = State(initialValue: Book(title: "", author: ""))
        case .edit(let existingBook):
            self._book = State(initialValue: existingBook)
        }
    }
    
    var body: some View {
        NavigationStack {
            BookFormView(
                book: $book,
                mode: mode,
                actionButton: {
                    BookAutoFillContainerButton(
                        targetBook: $book,
                        onAutoFillComplete: handleAutoFill
                    )
                },
                onSave: handleSave,
                onCancel: handleCancel
            )
            .navigationTitle(isEditMode ? "絵本を編集" : "絵本を追加")
            .interactiveDismissDisabled()
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertState.message)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isEditMode: Bool {
        if case .edit = mode {
            true
        } else {
            false
        }
    }
    
    // MARK: - Actions
    
    private func handleSave() {
        do {
            let savedBook: Book
            switch mode {
            case .add:
                savedBook = try bookModel.registerBook(book)
            case .edit:
                savedBook = try bookModel.updateBook(book)
            }
            
            onSave?(savedBook)
            dismiss()
        } catch {
            alertState = .error("保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func handleCancel() {
        dismiss()
    }
    
    private func handleAutoFill(_ filledBook: Book) {
        book = filledBook
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    
    return BookFormContainerView(mode: .add)
        .environment(bookModel)
}
