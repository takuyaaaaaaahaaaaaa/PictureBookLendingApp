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
    
    init(book: Book) {
        self._book = State(initialValue: book)
    }
    
    var body: some View {
        BookDetailView(
            book: $book,
            currentLoan: currentLoan,
            loanHistory: loanHistory,
        ) {
            LoanActionContainerButton(bookId: book.id)
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
