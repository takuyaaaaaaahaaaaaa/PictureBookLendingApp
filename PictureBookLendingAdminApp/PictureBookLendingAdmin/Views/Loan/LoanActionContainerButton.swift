import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 絵本の貸出アクションボタンContainer View
///
/// 貸出中かどうかに応じて貸出ボタンまたは返却ボタンを表示します。
/// Presentation ViewにUI表示を委譲し、ビジネスロジックのみを処理します。
struct LoanActionContainerButton: View {
    /// 対象絵本のID
    let bookId: UUID
    
    /// 絵本管理モデル
    @Environment(BookModel.self) private var bookModel
    /// 貸出管理モデル
    @Environment(LoanModel.self) private var loanModel
    /// ユーザ管理モデル
    @Environment(UserModel.self) private var userModel
    
    /// 貸出フォームシートの表示状態
    @State private var isLoanSheetPresented = false
    /// 返却確認アラートの表示状態
    @State private var isReturnConfirmationPresented = false
    /// アラート状態管理
    @State private var alertState = AlertState()
    
    /// bookIdから取得した絵本オブジェクト
    private var book: Book? {
        bookModel.findBookById(bookId)
    }
    
    /// 貸出中のユーザ名
    private var userName: String? {
        guard let loan = loanModel.getCurrentLoan(bookId: bookId) else { return nil }
        return loan.user.name
    }
    
    /// 絵本が貸出中かどうか
    private var isBookLent: Bool {
        loanModel.isBookLent(bookId: bookId)
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
            if let book = book {
                LoanFormContainerView(selectedBook: book)
                    .interactiveDismissDisabled()  // スワイプで閉じないようにする
            }
        }
        .alert("返却確認", isPresented: $isReturnConfirmationPresented) {
            Button("返却する", role: .destructive) {
                performReturn()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            if let book, let userName {
                VStack {
                    Text("利用者：\(userName) \nタイトル：\(book.title)")
                }
            }
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    // MARK: - Actions
    
    /// 貸出ボタンタップ時の処理
    private func handleLoanTap() {
        isLoanSheetPresented = true
    }
    
    /// 返却ボタンタップ時の処理
    private func handleReturnTap() {
        isReturnConfirmationPresented = true
    }
    
    /// 返却処理の実行
    private func performReturn() {
        Task {
            do {
                try loanModel.returnBook(bookId: bookId)
                alertState = .success("返却が完了しました")
            } catch {
                alertState = .error(error.localizedDescription)
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
    
    let sampleBook = Book(title: "はらぺこあおむし", author: "エリック・カール", managementNumber: "あ001")
    
    VStack(spacing: 16) {
        LoanActionContainerButton(bookId: sampleBook.id)
        
        // リスト内での表示例
        List {
            HStack {
                VStack(alignment: .leading) {
                    Text(sampleBook.title)
                        .font(.headline)
                    Text(sampleBook.author ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                LoanActionContainerButton(bookId: sampleBook.id)
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
