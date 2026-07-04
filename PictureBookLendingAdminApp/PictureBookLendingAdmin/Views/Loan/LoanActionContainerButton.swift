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
    /// アラート状態管理（エラー表示用）
    @Binding var alertState: AlertState
    /// 成功フィードバック状態管理（貸出用）
    @Binding var successFeedback: SuccessFeedback
    /// 取り消し可能フィードバック状態管理（返却用）
    @Binding var undoFeedback: UndoFeedback
    
    /// bookIdから取得した絵本オブジェクト
    private var book: Book? {
        bookModel.findBookById(bookId)
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
                RowActionButton(onTap: handleLoanTap)
            }
        }
        .sheet(isPresented: $isLoanSheetPresented) {
            if let book = book {
                LoanFormContainerView(selectedBook: book, onLoanSuccess: handleLoanSuccess)
                    .interactiveDismissDisabled()  // スワイプで閉じないようにする
            }
        }
    }
    
    // MARK: - Actions
    
    /// 貸出ボタンタップ時の処理
    private func handleLoanTap() {
        isLoanSheetPresented = true
    }
    
    /// 返却ボタンタップ時の処理
    ///
    /// 確認ダイアログは出さず即時返却し、「元に戻す」付きスナックバーで
    /// 取り消し手段を提供する（DESIGN_PRINCIPLES.md 原則2）。
    private func handleReturnTap() {
        performReturn()
    }
    
    /// 貸出成功時の処理
    private func handleLoanSuccess(userName: String) {
        successFeedback.show("\(userName)さんに貸出しました")
    }
    
    /// 返却処理の実行
    private func performReturn() {
        do {
            let returnedLoan = try loanModel.returnBook(bookId: bookId)
            let message =
                if let title = book?.title {
                    "『\(title)』を返却しました"
                } else {
                    "返却しました"
                }
            undoFeedback.show(message, targetId: returnedLoan.id)
        } catch {
            alertState = .error("返却処理に失敗しました", message: error.localizedDescription)
        }
    }
}

#Preview {
    
    @Previewable @State var alertState = AlertState()
    @Previewable @State var successFeedback = SuccessFeedback()
    @Previewable @State var undoFeedback = UndoFeedback()
    
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
        LoanActionContainerButton(
            bookId: sampleBook.id, alertState: $alertState, successFeedback: $successFeedback,
            undoFeedback: $undoFeedback)
        
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
                
                LoanActionContainerButton(
                    bookId: sampleBook.id, alertState: $alertState,
                    successFeedback: $successFeedback, undoFeedback: $undoFeedback)
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
