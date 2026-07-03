import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 家庭の枠領域のContainer View
///
/// 利用者ID（園児・保護者どちらでも可）から家庭を解決し、
/// 各枠の貸出状況を `FamilyLoanSlotsView` に供給します。
/// 返却の実行とUndoフィードバックまでを担当し、
/// 完了後の遷移（一覧へ戻る等）は呼び出し元に委ねます。
struct FamilyLoanSlotsContainerView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(LoanModel.self) private var loanModel
    @Environment(BookModel.self) private var bookModel
    
    /// アラート状態管理（エラー表示用）
    @Binding var alertState: AlertState
    /// 返却のUndoフィードバック状態管理
    @Binding var undoFeedback: UndoFeedback
    
    /// 家庭を特定する利用者ID（園児・保護者どちらでも可）
    let userId: UUID
    /// 文脈（返却／貸出）
    let mode: FamilyLoanSlotsMode
    /// 返却完了時の動作（引数は家庭内にまだ貸出中の本が残っているか。
    /// 一覧へ自動で戻る等の遷移は呼び出し元が決める）
    let onReturnCompleted: (_ hasRemainingLoans: Bool) -> Void
    /// 貸出文脈で枠が選ばれたときの動作（引数は枠の持ち主の利用者ID）
    let onBorrowSlotSelected: (UUID) -> Void
    
    var body: some View {
        FamilyLoanSlotsView(
            slots: slots,
            mode: mode,
            onReturn: handleReturn(_:),
            onBorrow: { onBorrowSlotSelected($0.id) }
        )
    }
    
    // MARK: - Computed Properties
    
    /// 家庭の全員分の枠表示データ
    ///
    /// 現状は1人1枠（maxBooksPerUser=1の運用前提）。複数冊設定時の枠の積み方は
    /// SCREEN_DESIGN_PHASE2 §8 の未決事項として実装時に拡張する。
    private var slots: [FamilyLoanSlotDisplay] {
        userModel.getFamilyMembers(of: userId).map { member in
            FamilyLoanSlotDisplay(
                id: member.id,
                roleLabel: Self.roleLabel(for: member),
                memberName: member.name,
                loan: loanDisplay(for: member)
            )
        }
    }
    
    private static func roleLabel(for member: User) -> String {
        switch member.userType.category {
        case .child: "園児の本"
        case .guardian: "保護者の本"
        }
    }
    
    private func loanDisplay(for member: User) -> FamilyLoanSlotLoan? {
        guard let loan = loanModel.getUserActiveLoans(userId: member.id).first,
            let book = bookModel.findBookById(loan.bookId)
        else { return nil }
        
        return FamilyLoanSlotLoan(
            bookTitle: book.title,
            imageURL: book.resolvedSmallImageSource,
            dueDateText: loan.dueDateText,
            isOverdue: loan.isOverdue(at: Date())
        )
    }
    
    // MARK: - Actions
    
    /// 返却の実行（確認ダイアログなし・Undoカードでリカバリー）
    private func handleReturn(_ slot: FamilyLoanSlotDisplay) {
        guard let loan = loanModel.getUserActiveLoans(userId: slot.id).first else { return }
        
        do {
            let returnedLoan = try loanModel.returnBook(loanId: loan.id)
            let message =
                if let title = bookModel.findBookById(returnedLoan.bookId)?.title {
                    "『\(title)』を返却しました"
                } else {
                    "返却しました"
                }
            undoFeedback.show(message, targetId: returnedLoan.id)
            let hasRemainingLoans = userModel.getFamilyMembers(of: slot.id)
                .contains { !loanModel.getUserActiveLoans(userId: $0.id).isEmpty }
            onReturnCompleted(hasRemainingLoans)
        } catch {
            alertState = .error("返却処理に失敗しました", message: error.localizedDescription)
        }
    }
}

#Preview("返却文脈（実データ相当）") {
    @Previewable @State var alertState = AlertState()
    @Previewable @State var undoFeedback = UndoFeedback()
    
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let loanModel = LoanModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository,
        loanSettingsRepository: mockFactory.loanSettingsRepository
    )
    
    // 家庭（園児＋保護者）と貸出中の本をセットアップ
    let child = try! userModel.registerUser(User(name: "いとう さくら", classGroupId: UUID()))
    let mother = try! userModel.registerUser(
        User(
            name: "伊藤 由美子", classGroupId: child.classGroupId,
            userType: .guardian(relatedChildId: child.id)))
    let book = try! bookModel.registerBook(Book(title: "ぐりとぐら", author: "中川李枝子"))
    _ = try! loanModel.lendBook(bookId: book.id, userId: child.id)
    
    return ScrollView {
        FamilyLoanSlotsContainerView(
            alertState: $alertState,
            undoFeedback: $undoFeedback,
            userId: mother.id,  // 保護者のIDから入っても同じ家庭に解決される
            mode: .returning,
            onReturnCompleted: { _ in },
            onBorrowSlotSelected: { _ in }
        )
        .padding()
    }
    .undoFeedback($undoFeedback, onUndo: {})
    .environment(userModel)
    .environment(loanModel)
    .environment(bookModel)
}
