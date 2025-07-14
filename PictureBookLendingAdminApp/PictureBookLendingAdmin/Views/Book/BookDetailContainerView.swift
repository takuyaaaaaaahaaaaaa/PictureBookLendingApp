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
    @Environment(LendingModel.self) private var lendingModel
    
    let initialBook: Book
    
    @State private var book: Book
    @State private var isEditSheetPresented = false
    @State private var isCurrentlyLent = false
    
    init(book: Book) {
        self.initialBook = book
        self._book = State(initialValue: book)
    }
    
    var body: some View {
        BookDetailView(
            book: book,
            isCurrentlyLent: isCurrentlyLent,
            onEdit: handleEdit
        )
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    isEditSheetPresented = true
                }
            }
        }
        .sheet(isPresented: $isEditSheetPresented) {
            BookFormContainerView(
                mode: .edit(book),
                onSave: handleBookSaved
            )
        }
        .onAppear {
            checkLendingStatus()
        }
    }
    
    // MARK: - Actions
    
    private func handleEdit() {
        isEditSheetPresented = true
    }
    
    private func handleBookSaved(_ savedBook: Book) {
        book = savedBook
        checkLendingStatus()
    }
    
    private func checkLendingStatus() {
        isCurrentlyLent = lendingModel.isBookLent(bookId: book.id)
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    let sampleBook = Book(title: "はらぺこあおむし", author: "エリック・カール")
    
    return NavigationStack {
        BookDetailContainerView(book: sampleBook)
            .environment(lendingModel)
    }
}
