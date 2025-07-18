import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出ボタンのContainer View
///
/// 貸出ボタンのタップ処理とフロー開始を担当します。
/// Presentation ViewにUI表示を委譲し、ビジネスロジックのみを処理します。
struct LoanContainerButton: View {
    let book: Book
    @State private var isLoanSheetPresented = false
    
    var body: some View {
        LoanButtonView(onTap: handleTap)
            .sheet(isPresented: $isLoanSheetPresented) {
                LoanFormContainerView(selectedBook: book)
            }
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        isLoanSheetPresented = true
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
        LoanContainerButton(book: sampleBook)
        
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
                
                LoanContainerButton(book: sampleBook)
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
