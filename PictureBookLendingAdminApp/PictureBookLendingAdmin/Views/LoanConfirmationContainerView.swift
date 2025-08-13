import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出確認画面のコンテナビュー
struct LoanConfirmationContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LoanModel.self) private var loanModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    let book: Book
    let user: User
    let onComplete: () -> Void
    
    @State private var alertState = AlertState()
    
    private var classGroup: ClassGroup? {
        classGroupModel.findClassGroupById(user.classGroupId)
    }
    
    private var dueDate: Date {
        Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    }
    
    var body: some View {
        Group {
            if let classGroup = classGroup {
                LoanConfirmationView(
                    book: book,
                    user: user,
                    classGroup: classGroup,
                    dueDate: dueDate,
                    onConfirm: confirmLoan,
                    onCancel: cancelLoan
                )
            } else {
                ContentUnavailableView(
                    "組情報が見つかりません",
                    systemImage: "exclamationmark.triangle",
                    description: Text("利用者の組情報を確認してください")
                )
            }
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private func confirmLoan() {
        do {
            let _ = try loanModel.lendBook(
                bookId: book.id,
                userId: user.id
            )
            onComplete()
            dismiss()
        } catch {
            alertState = .error("貸出処理に失敗しました")
        }
    }
    
    private func cancelLoan() {
        dismiss()
    }
}

#Preview {
    LoanConfirmationContainerView(
        book: Book(title: "はらぺこあおむし", author: "エリック・カール"),
        user: User(name: "山田太郎", classGroupId: UUID()),
        onComplete: {}
    )
    .environment(
        LoanModel(
            repository: MockLoanRepository(),
            bookRepository: MockBookRepository(),
            userRepository: MockUserRepository(),
            loanSettingsRepository: MockLoanSettingsRepository()
        )
    )
    .environment(ClassGroupModel(repository: MockClassGroupRepository()))
}
