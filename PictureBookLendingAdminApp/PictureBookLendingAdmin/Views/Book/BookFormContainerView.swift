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
    
    @State private var title = ""
    @State private var author = ""
    @State private var managementNumber = ""
    @State private var alertState = AlertState()
    
    var body: some View {
        NavigationStack {
            BookFormView(
                title: $title,
                author: $author,
                managementNumber: $managementNumber,
                mode: mode,
                onSave: handleSave,
                onCancel: handleCancel
            )
            .navigationTitle(isEditMode ? "絵本を編集" : "絵本を追加")
            .onAppear {
                // 編集モードの場合、初期値をセット
                if case .edit(let book) = mode {
                    title = book.title
                    author = book.author
                    managementNumber = book.managementNumber ?? ""
                }
            }
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
            switch mode {
            case .add:
                let newBook = Book(
                    title: title,
                    author: author,
                    managementNumber: managementNumber
                )
                let savedBook = try bookModel.registerBook(newBook)
                onSave?(savedBook)

            case .edit(let book):
                let updatedBook = Book(
                    id: book.id,
                    title: title,
                    author: author,
                    isbn13: book.isbn13,
                    publisher: book.publisher,
                    publishedDate: book.publishedDate,
                    description: book.description,
                    smallThumbnail: book.smallThumbnail,
                    thumbnail: book.thumbnail,
                    targetAge: book.targetAge,
                    pageCount: book.pageCount,
                    categories: book.categories,
                    managementNumber: managementNumber.isEmpty ? nil : managementNumber
                )
                let savedBook = try bookModel.updateBook(updatedBook)
                onSave?(savedBook)
            }
            
            dismiss()
        } catch {
            alertState = .error("保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func handleCancel() {
        dismiss()
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    
    return BookFormContainerView(mode: .add)
        .environment(bookModel)
}
