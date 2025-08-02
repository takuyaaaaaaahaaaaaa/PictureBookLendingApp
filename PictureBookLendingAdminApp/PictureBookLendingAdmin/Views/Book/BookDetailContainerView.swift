import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 絵本詳細のContainer View
///
/// ビジネスロジック、状態管理、データ取得を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct BookDetailContainerView: View {
    @Environment(LoanModel.self) private var loanModel
    @Environment(BookModel.self) private var bookModel
    
    @State private var book: Book
    @State private var isEditSheetPresented = false
    @State private var alertState = AlertState()
    
    init(book: Book) {
        self._book = State(initialValue: book)
    }
    
    var body: some View {
        BookDetailView(
            book: $book,
            isCurrentlyLent: isCurrentlyLent,
            onEdit: handleEdit
        ) {
            LoanActionContainerButton(bookId: book.id)
        }
        .navigationTitle(book.title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("編集") {
                    isEditSheetPresented = true
                }
            }
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .onChange(of: book) { _, newValue in
            do {
                _ = try bookModel.updateBook(newValue)
            } catch {
                alertState = .error(error.localizedDescription)
            }
        }
    }
    
    private var isCurrentlyLent: Bool {
        loanModel.isBookLent(bookId: book.id)
    }
    
    // MARK: - Actions
    
    private func handleEdit() {
        isEditSheetPresented = true
    }
    
    private func handleBookSaved(_ savedBook: Book) {
        book = savedBook
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let loanModel = LoanModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository,
        loanSettingsRepository: mockFactory.loanSettingsRepository
    )
    
    let sampleBook = Book(title: "はらぺこあおむし", author: "エリック・カール")
    
    NavigationStack {
        BookDetailContainerView(book: sampleBook)
            .environment(loanModel)
    }
}
