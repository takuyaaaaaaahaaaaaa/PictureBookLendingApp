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
    @State private var alertState = AlertState()
    @State private var successFeedback = SuccessFeedback()
    @State private var undoFeedback = UndoFeedback()
    
    init(book: Book) {
        self._book = State(initialValue: book)
    }
    
    var body: some View {
        BookDetailView(
            book: $book,
            imageURL: book.resolvedImageSource,
            currentLoan: currentLoan,
            loanHistory: loanHistory,
        ) {
            LoanActionContainerButton(
                bookId: book.id, alertState: $alertState, successFeedback: $successFeedback,
                undoFeedback: $undoFeedback)
        }
        .navigationTitle(book.title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .successFeedback($successFeedback)
        .undoSnackbar($undoFeedback, onUndo: handleUndoReturn)
        .onChange(of: book) { _, newValue in
            do {
                _ = try bookModel.updateBook(newValue)
            } catch {
                alertState = .error("絵本情報の更新に失敗しました", message: error.localizedDescription)
            }
        }
    }
    
    private var currentLoan: Loan? {
        loanModel.getCurrentLoan(bookId: book.id)
    }
    
    private var loanHistory: [Loan] {
        loanModel.getLoansByBook(bookId: book.id)
            .sorted { $0.loanDate > $1.loanDate }  // 新しい順にソート
    }
    
    /// 返却の取り消し（スナックバーの「元に戻す」）
    private func handleUndoReturn() {
        guard let loanId = undoFeedback.targetId else { return }
        do {
            try loanModel.undoReturn(loanId: loanId)
        } catch {
            alertState = .error("返却の取り消しに失敗しました", message: error.localizedDescription)
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
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
            .environment(bookModel)
            .environment(userModel)
    }
}
