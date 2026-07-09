import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出シートのContainer View（図書一覧から開く子シート）
///
/// 一時的な貸出タスク（「だれが借りますか？」→「どの枠で借りますか？」→ ✓カード）を
/// シートの中だけで完結させる。シート表示ごとに@Stateごと生成・破棄されるため、
/// 遷移パスや組の絞り込みは初期値（空・全組）から必ず始まる。前回の貸出の状態は残らない。
///
/// このViewの@State（`sheetPath`・`selectedClassGroupId`・各種フィードバック等）は
/// すべてシート内フロー専用。「画面の境界＝状態の境界」に従い、
/// 図書一覧（親）の状態とは混ぜない。
///
/// 親への通知はクロージャで最小限に：
/// - `onClose`: ✕ボタン・無操作タイムアウトでシートを閉じるだけ
/// - `onLendCompleted`: ✓カードが消えた後、シートを閉じて次の貸出へ引き継ぐ
///   （図書一覧の絞り込み解除・先頭スクロールは親側の状態なので親に委ねる）
struct BorrowSheetContainerView: View {
    @Environment(LoanModel.self) private var loanModel
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    /// フォームシート内部の遷移パス（利用者選択→枠確認）
    @State private var sheetPath = NavigationPath()
    /// 利用者選択画面で組チップにより絞り込み中の組ID（nilなら全組）
    @State private var selectedClassGroupId: UUID?
    @State private var alertState = AlertState()
    @State private var successFeedback = SuccessFeedback()
    /// 貸出後、✓カードの表示が終わったらシートを閉じる（図書一覧へ戻す）ための予約フラグ
    @State private var isPopPendingAfterLend = false
    /// 選択画面の無操作タイマーのトークン（操作のたびに更新して待ち時間を延長する）
    @State private var idleTicket = 0
    /// 枠確認画面での返却（本の入れ替え）用のUndoカード状態
    @State private var undoFeedback = UndoFeedback()
    
    /// タップされた図書と開いた時点の貸出状態のスナップショット（シートの提示単位）
    let context: BorrowSheetContext
    /// シートを閉じるだけの要求（✕ボタン・無操作タイムアウト）
    let onClose: () -> Void
    /// 貸出が完了し✓カードも消えたときの通知（親が図書一覧を次の貸出へ引き継ぐ）
    let onLendCompleted: () -> Void
    
    /// 貸出成功の✓カードの表示時間。カードの消滅がシートを閉じる合図を兼ねるため、
    /// 既定の1.5秒では読み切る前に画面が変わってしまう。読み切れる長さに延ばす
    private static let lendFeedbackDuration: Duration = .seconds(2.5)
    
    private enum Layout {
        static let sectionSpacing: CGFloat = 24
        static let headerContentSpacing: CGFloat = 16
        static let headerTextSpacing: CGFloat = 4
        /// 表紙サムネイル（家庭の枠の貸出中カードと同じ寸法で揃える）
        static let thumbnailWidth: CGFloat = 56
        static let thumbnailHeight: CGFloat = 72
        static let thumbnailCornerRadius: CGFloat = 6
    }
    
    var body: some View {
        NavigationStack(path: $sheetPath) {
            borrowerPickScreen(for: context)
                .navigationDestination(for: BorrowConfirmRoute.self) { route in
                    slotConfirmScreen(for: route)
                }
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .successFeedback($successFeedback, displayDuration: Self.lendFeedbackDuration)
        // 枠確認画面での返却（本の入れ替え）に対するUndoカード。
        // 取り消してもその場に留まり、枠に本が戻るのを見せる
        .undoFeedback($undoFeedback, onUndo: handleUndoReturn)
        .onChange(of: successFeedback.isPresented) { wasPresented, isPresented in
            // ✓カードがタイムアウトで消えたらシートを閉じる
            if wasPresented && !isPresented && isPopPendingAfterLend {
                isPopPendingAfterLend = false
                // 貸出完了→次の貸出のために親へ通知（絞り込み解除・先頭スクロールは親側の状態）
                onLendCompleted()
            }
        }
        // 誤スワイプで貸出タスクが途中で消えないようにする（閉じるのは✕ボタンから。
        // 絵本管理の貸出フォームと同じ作法）
        .interactiveDismissDisabled()
    }
    
    // MARK: - Private Views
    
    /// 利用者選択画面（フォームシートの最初の画面・「だれが借りますか？」）
    ///
    /// 貸出中の図書が選ばれた場合は貸出できない理由を説明する空状態を表示する。
    /// 判定はitemに焼き込んだスナップショットを使う（理由は`BorrowSheetContext`参照）
    private func borrowerPickScreen(for context: BorrowSheetContext) -> some View {
        sheetScreen(title: "だれが借りますか？") {
            if context.isAlreadyLent {
                ContentUnavailableView(
                    "この図書は貸出中です",
                    systemImage: "book.closed",
                    description: Text(lentBookDescription(for: context.book))
                )
            } else {
                BorrowerListView(
                    sections: allUserSections,
                    // 自分の組が分かっていて切り替えたい画面なので、
                    // チップはインデックスではなくフィルタとして動作させる
                    chipBehavior: .filter(selection: $selectedClassGroupId),
                    emptyStateTitle: "利用者が登録されていません",
                    emptyStateDescription: "設定画面から利用者を登録してください",
                    onSelect: { row in
                        sheetPath.append(BorrowConfirmRoute(book: context.book, userId: row.id))
                    }
                )
            }
        }
    }
    
    /// 枠確認画面（シート内で利用者タップから進む先・「どの枠で借りますか？」）
    ///
    /// 選んだ図書の要約（表紙＋タイトル＋著者）を上部に示し、
    /// 家庭の枠領域（貸出文脈）で空き枠を選ばせる。
    /// 表紙の見た目は家庭の枠の貸出中カードと同じ作法（サイズ・角丸）で揃える
    private func slotConfirmScreen(for route: BorrowConfirmRoute) -> some View {
        sheetScreen(title: "どの枠で借りますか？") {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    HStack(spacing: Layout.headerContentSpacing) {
                        BookImageView(imageURL: route.book.resolvedSmallImageSource) {
                            Image(systemName: "book.closed")
                                .foregroundStyle(.secondary)
                                .font(.title2)
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Layout.thumbnailWidth, height: Layout.thumbnailHeight)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: Layout.thumbnailCornerRadius))
                        
                        VStack(alignment: .leading, spacing: Layout.headerTextSpacing) {
                            Text("『\(route.book.title)』")
                                .font(.title3.bold())
                            if let author = route.book.author {
                                Text(author)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    FamilyLoanSlotsContainerView(
                        undoFeedback: $undoFeedback,
                        userId: route.userId,
                        context: .borrowing(onSlotSelected: { slotUserId in
                            handleLend(book: route.book, userId: slotUserId)
                        })
                    )
                }
                .padding()
            }
        }
    }
    
    /// シート内画面の共通装飾（無操作タイマー・インラインタイトル・✕閉じるボタン）
    ///
    /// ✕ボタンは、下スワイプでの閉じ方を知らない利用者のための明示的な閉じる手段
    private func sheetScreen(
        title: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            // コンテンツ領域のタッチ（タップ・スクロール）で無操作タイマーを延長する。
            // 200人の一覧をゆっくり探している最中に置き去り扱いで閉じないようにする。
            // ナビバー（戻る・✕）には掛けない：バーのボタンのタッチと競合して
            // 戻るボタンが効かなくなるため、コンテンツにだけ付ける
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in idleTicket += 1 }
            )
            .kioskIdleTimeout(ticket: idleTicket) { onClose() }
            .navigationTitle(title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            #endif
    }
    
    // MARK: - Computed Properties
    
    /// 利用者選択画面の組セクション（組ごとに名前順）
    ///
    /// 一覧から隠すのは「別の入口から構造的に到達できる利用者」＝保護者だけ
    /// （保護者の枠は園児タップ後の家庭の画面から必ず選べる。IA_REVIEW 追記12）。
    /// 園児と、大人の組の独立利用者（先生・職員）はそのまま表示する。
    /// 紐づく園児が実在しない保護者は入口を失うため、本人を表示するフォールバック。
    /// 家庭の全員が借用中の行には「空き枠なし」バッジを付け、タップ前に結果を知らせる。
    /// 一覧に出す利用者の判定は`userModel.getFamilyEntranceUsers()`に委譲する。
    private var allUserSections: [BorrowerListSection] {
        let allUsers = userModel.getAllUsers()
        let entranceUsers = userModel.getFamilyEntranceUsers()
        
        // 空き枠判定の材料：借用中の利用者IDと、園児→紐づく保護者の対応表
        let borrowedUserIds = Set(loanModel.activeLoans.map { $0.user.id })
        var guardiansByChildId: [UUID: [User]] = [:]
        for user in allUsers {
            if case .guardian(let relatedChildId) = user.userType {
                guardiansByChildId[relatedChildId, default: []].append(user)
            }
        }
        
        return Dictionary(grouping: entranceUsers) { $0.classGroupId }
            .map { classGroupId, users in
                BorrowerListSection(
                    id: classGroupId,
                    title: classGroupModel.findClassGroupById(classGroupId)?.name ?? "未分類",
                    rows:
                        users
                        .sorted { $0.name < $1.name }
                        .map { user in
                            // 家庭の全員（本人＋紐づく保護者）が借用中なら空き枠なし
                            let familyMembers = [user] + (guardiansByChildId[user.id] ?? [])
                            return BorrowerRowDisplay(
                                id: user.id,
                                name: user.name,
                                isGuardian: user.userType.category == .guardian,
                                isOverdue: false,
                                hasNoOpenSlot: familyMembers.allSatisfy {
                                    borrowedUserIds.contains($0.id)
                                }
                            )
                        }
                )
            }
            .sorted { $0.title < $1.title }
    }
    
    /// 貸出中の図書の説明文（「いつ戻るか」の目安を日付だけで知らせる）
    ///
    /// 誰が借りているかは表示しない（プライバシー配慮・IA_REVIEW 追記13）
    private func lentBookDescription(for book: Book) -> String {
        if let loan = loanModel.getCurrentLoan(bookId: book.id) {
            "\(loan.dueDateText)ごろ返却予定です"
        } else {
            "返却されると貸出できるようになります"
        }
    }
    
    // MARK: - Actions
    
    /// 枠確認画面での返却の取り消し（Undoカードの「元に戻す」）
    ///
    /// 取り消したらその場に留まり、枠に本が戻るのを見せる
    private func handleUndoReturn() {
        guard let loanId = undoFeedback.targetId else { return }
        do {
            try loanModel.undoReturn(loanId: loanId)
        } catch {
            alertState = .error("返却の取り消しに失敗しました", message: error.localizedDescription)
        }
    }
    
    /// 貸出の実行（枠選択のタップで確定・✓カードで完了を伝える）
    private func handleLend(book: Book, userId: UUID) {
        do {
            _ = try loanModel.lendBook(bookId: book.id, userId: userId)
            let name = userModel.findUserById(userId)?.name ?? ""
            successFeedback.show("\(name)さんに『\(book.title)』を貸出しました")
            isPopPendingAfterLend = true
            idleTicket += 1
        } catch {
            alertState = .error("貸出に失敗しました", message: error.localizedDescription)
        }
    }
}

/// 枠確認画面への遷移値（選んだ図書＋家庭を特定する利用者ID）
private struct BorrowConfirmRoute: Hashable {
    let book: Book
    let userId: UUID
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    let loanModel = LoanModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository,
        loanSettingsRepository: mockFactory.loanSettingsRepository
    )
    
    // 組1つ・園児2人（うち1人に保護者を紐付け）・図書1冊（貸出可能）をセットアップ
    let momo = ClassGroup(name: "もも組", ageGroup: AgeGroup.age(4), year: 2026)
    try! mockFactory.classGroupRepository.save(momo)
    
    let sakura = try! userModel.registerUser(User(name: "いとう さくら", classGroupId: momo.id))
    _ = try! userModel.registerUser(
        User(
            name: "伊藤 由美子", classGroupId: momo.id,
            userType: .guardian(relatedChildId: sakura.id)))
    _ = try! userModel.registerUser(User(name: "あおき はると", classGroupId: momo.id))
    
    let guriToGura = try! bookModel.registerBook(Book(title: "ぐりとぐら", author: "中川李枝子"))
    
    return BorrowSheetContainerView(
        context: BorrowSheetContext(book: guriToGura, isAlreadyLent: false),
        onClose: {},
        onLendCompleted: {}
    )
    .environment(userModel)
    .environment(loanModel)
    .environment(classGroupModel)
}
