import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 絵本のアクションボタンContainer View
///
/// 貸出中かどうかに応じて貸出ボタンまたは返却ボタンを表示します。
/// Presentation ViewにUI表示を委譲し、ビジネスロジックのみを処理します。
struct BookActionContainerButton: View {
    let book: Book
    @Environment(LoanModel.self) private var loanModel
    @State private var isLoanSheetPresented = false
    @State private var alertState = AlertState()
    
    private var isBookLent: Bool {
        loanModel.isBookLent(bookId: book.id)
    }
    
    var body: some View {
        VStack {
            if isBookLent {
                ReturnButtonView(onTap: handleReturnTap)
            } else {
                LoanButtonView(onTap: handleLoanTap)
            }
        }
        .sheet(isPresented: $isLoanSheetPresented) {
            LoanFormContainerView(selectedBook: book)
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    // MARK: - Actions
    
    private func handleLoanTap() {
        isLoanSheetPresented = true
    }
    
    private func handleReturnTap() {
        Task {
            do {
                try loanModel.returnBook(bookId: book.id)
                alertState = .success("返却が完了しました")
            } catch {
                alertState = .error("返却に失敗しました: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    let mockRepositoryFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockRepositoryFactory.bookRepository)
    let userModel = UserModel(repository: mockRepositoryFactory.userRepository)
    let loanModel = LoanModel(
        repository: mockRepositoryFactory.loanRepository,
        bookRepository: mockRepositoryFactory.bookRepository,
        userRepository: mockRepositoryFactory.userRepository,
        loanSettingsRepository: mockRepositoryFactory.loanSettingsRepository
    )
    let classGroupModel = ClassGroupModel(repository: mockRepositoryFactory.classGroupRepository)
    
    let sampleBook = Book(title: "はらぺこあおむし", author: "エリック・カール")
    
    VStack(spacing: 16) {
        BookActionContainerButton(book: sampleBook)
        
        // リスト内での表示例
        List {
            HStack {
                VStack(alignment: .leading) {
                    Text(sampleBook.title)
                        .font(.headline)
                    Text(sampleBook.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                BookActionContainerButton(book: sampleBook)
            }
            .padding(.vertical, 4)
        }
    }
    .padding()
    .environment(bookModel)
    .environment(userModel)
    .environment(loanModel)
    .environment(classGroupModel)
}
