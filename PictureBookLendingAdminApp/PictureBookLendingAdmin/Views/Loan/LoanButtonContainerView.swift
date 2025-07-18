import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import SwiftUI

/// 貸出ボタンのContainer View
///
/// 貸出ボタンのタップ処理とフロー開始を担当します。
struct LoanButtonContainerView: View {
    let book: Book
    @State private var isLoanSheetPresented = false
    
    var body: some View {
        Button(action: {
            isLoanSheetPresented = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle")
                    .font(.caption)
                Text("貸出")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isLoanSheetPresented) {
            LoanFormContainerView(preselectedBookId: book.id)
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
        LoanButtonContainerView(book: sampleBook)
        
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
                
                LoanButtonContainerView(book: sampleBook)
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
