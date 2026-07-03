import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 返却モードのContainer View（返却タブのルート）
///
/// 現在貸出中の利用者を名前のみで一覧表示し、名前タップで家庭の画面へ遷移します。
/// 「延滞のみ」フィルタにより先生の月末俯瞰を兼ねます（SCREEN_DESIGN_PHASE2 §3）。
/// 検索は名前でも図書タイトルでもヒットします（本を手に持って来る人向け）。
struct ReturnListContainerView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(LoanModel.self) private var loanModel
    @Environment(BookModel.self) private var bookModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    @State private var navigationPath = NavigationPath()
    @State private var searchText = ""
    @State private var isOverdueOnly = false
    /// 一覧をトップへ戻すトリガ（返却完了ごとにインクリメント）
    @State private var scrollToTopTrigger = 0
    /// 返却後、Undoカードの表示が終わったら一覧へ戻るための予約フラグ
    @State private var isPopPendingAfterReturn = false
    /// 家庭の画面の無操作タイマーのトークン（操作のたびに更新して待ち時間を延長する）
    @State private var idleTicket = 0
    @State private var alertState = AlertState()
    @State private var undoFeedback = UndoFeedback()
    
    /// 家庭の画面の無操作タイムアウト。貸出が残っていて操作がないまま
    /// この時間が経過したら、置き去りとみなして一覧トップへ戻る
    /// （次の利用者に家庭の情報を見せないためのキオスク作法）
    private static let familyScreenIdleTimeout: Duration = .seconds(15)
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            BorrowerListView(
                sections: filteredSections,
                scrollToTopTrigger: scrollToTopTrigger,
                isOverdueOnly: $isOverdueOnly,
                onSelect: handleSelect(_:)
            )
            .navigationTitle("返却")
            #if os(iOS)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "名前 または 図書のタイトルで検索")
            #else
                .searchable(text: $searchText, prompt: "名前 または 図書のタイトルで検索")
            #endif
            .navigationDestination(for: UUID.self) { userId in
                familyScreen(for: userId)
            }
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .undoFeedback($undoFeedback, onUndo: handleUndoReturn)
        .onChange(of: undoFeedback.isPresented) { wasPresented, isPresented in
            // カードがタイムアウトで消えたら一覧へ戻る（Undoで消えた場合は
            // handleUndoReturnが先に予約を取り消しているため、その場に留まる）
            if wasPresented && !isPresented && isPopPendingAfterReturn {
                isPopPendingAfterReturn = false
                popToListAndScrollTop()
            }
        }
        .onAppear {
            refreshData()
        }
        .refreshable {
            refreshData()
        }
    }
    
    // MARK: - Private Views
    
    /// 家庭の画面（名前タップのプッシュ先）
    private func familyScreen(for userId: UUID) -> some View {
        ScrollView {
            FamilyLoanSlotsContainerView(
                alertState: $alertState,
                undoFeedback: $undoFeedback,
                userId: userId,
                mode: .returning,
                onReturnCompleted: handleReturnCompleted(hasRemainingLoans:),
                onBorrowSlotSelected: { _ in }
            )
            .padding()
        }
        .task(id: idleTicket) {
            // 無操作タイムアウト：操作（返却・取り消し）のたびにidleTicketが変わり、
            // タスクが再起動して待ち時間が延長される。画面を離れると自動キャンセルされる
            try? await Task.sleep(for: Self.familyScreenIdleTimeout)
            if Task.isCancelled { return }
            popToListAndScrollTop()
        }
        .navigationTitle(userModel.findUserById(userId)?.name ?? "")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    // MARK: - Computed Properties
    
    /// 借用者1人分の内部データ（フィルタ用に非表示の図書タイトルも保持）
    private struct BorrowerEntry {
        let row: BorrowerRowDisplay
        let classGroupId: UUID
        let bookTitles: [String]
    }
    
    /// 貸出中の利用者一覧（名前順）
    private var borrowerEntries: [BorrowerEntry] {
        let now = Date()
        // 注意: getActiveLoans()はキャッシュ更新の副作用を持ちbody評価中に呼ぶと
        // 再描画ループになるため、副作用のないgetAllLoans()から絞り込む
        let activeLoans = loanModel.getAllLoans().filter { !$0.isReturned }
        let loansByUser = Dictionary(grouping: activeLoans) { $0.user.id }
        
        return
            loansByUser
            .compactMap { userId, loans -> BorrowerEntry? in
                guard let first = loans.first else { return nil }
                // 名前・種別は現在の利用者情報を優先し、削除済みなら貸出時のスナップショットを使う
                let user = userModel.findUserById(userId) ?? first.user
                return BorrowerEntry(
                    row: BorrowerRowDisplay(
                        id: userId,
                        name: user.name,
                        isGuardian: user.userType.category == .guardian,
                        isOverdue: loans.contains { $0.isOverdue(at: now) }
                    ),
                    classGroupId: user.classGroupId,
                    bookTitles: loans.compactMap { bookModel.findBookById($0.bookId)?.title }
                )
            }
            .sorted { $0.row.name < $1.row.name }
    }
    
    /// 検索・延滞フィルタを適用した借用者（組はフィルタせずインデックスでスクロール）
    private var filteredEntries: [BorrowerEntry] {
        borrowerEntries
            .filter { entry in
                if isOverdueOnly && !entry.row.isOverdue {
                    return false
                }
                if !searchText.isEmpty {
                    let matchesName = entry.row.name.localizedStandardContains(searchText)
                    let matchesTitle = entry.bookTitles.contains {
                        $0.localizedStandardContains(searchText)
                    }
                    return matchesName || matchesTitle
                }
                return true
            }
    }
    
    /// 組セクション単位の表示データ（既存の貸出管理・絵本一覧と同じ見た目の慣習）
    private var filteredSections: [BorrowerListSection] {
        Dictionary(grouping: filteredEntries) { $0.classGroupId }
            .map { classGroupId, entries in
                BorrowerListSection(
                    id: classGroupId,
                    title: classGroupModel.findClassGroupById(classGroupId)?.name ?? "未分類",
                    rows: entries.map(\.row)
                )
            }
            .sorted { $0.title < $1.title }
    }
    
    // MARK: - Actions
    
    private func handleSelect(_ row: BorrowerRowDisplay) {
        navigationPath.append(row.id)
    }
    
    /// 返却完了時：すぐには戻らず、Undoカードの表示中は家庭の画面に留まる
    /// （枠が「借りていません」に変わるのを見せて確認とする＝状態が画面に残る原則）。
    /// 家庭の本がすべて返ったときだけ、カードが消えた後に一覧へ自動で戻る。
    /// まだ貸出が残っていれば留まり続け、2冊目の返却を時間制限なしで行える
    private func handleReturnCompleted(hasRemainingLoans: Bool) {
        isPopPendingAfterReturn = !hasRemainingLoans
        idleTicket += 1
    }
    
    /// 一覧のトップへ戻る（次の親子への画面の引き継ぎ）
    private func popToListAndScrollTop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
        scrollToTopTrigger += 1
    }
    
    /// 返却の取り消し（Undoカードの「元に戻す」）
    ///
    /// 取り消したらその場（家庭の画面）に留まり、枠に本が戻るのを見せる
    private func handleUndoReturn() {
        isPopPendingAfterReturn = false
        idleTicket += 1
        guard let loanId = undoFeedback.targetId else { return }
        do {
            try loanModel.undoReturn(loanId: loanId)
        } catch {
            alertState = .error("返却の取り消しに失敗しました", message: error.localizedDescription)
        }
    }
    
    private func refreshData() {
        userModel.refreshUsers()
        loanModel.refreshLoans()
        bookModel.refreshBooks()
        classGroupModel.refreshClassGroups()
    }
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
    
    // 家庭2組と貸出をセットアップ
    let momo = ClassGroup(name: "もも組", ageGroup: AgeGroup.age(4), year: 2026)
    try! mockFactory.classGroupRepository.save(momo)
    
    let sakura = try! userModel.registerUser(User(name: "いとう さくら", classGroupId: momo.id))
    let yumiko = try! userModel.registerUser(
        User(
            name: "伊藤 由美子", classGroupId: momo.id,
            userType: .guardian(relatedChildId: sakura.id)))
    let haruto = try! userModel.registerUser(User(name: "あおき はると", classGroupId: momo.id))
    
    let guriToGura = try! bookModel.registerBook(Book(title: "ぐりとぐら", author: "中川李枝子"))
    let daiku = try! bookModel.registerBook(Book(title: "だいくとおにろく", author: "松居直"))
    let aomushi = try! bookModel.registerBook(Book(title: "はらぺこあおむし", author: "エリック・カール"))
    
    _ = try! loanModel.lendBook(bookId: guriToGura.id, userId: sakura.id)
    _ = try! loanModel.lendBook(bookId: daiku.id, userId: yumiko.id)
    _ = try! loanModel.lendBook(bookId: aomushi.id, userId: haruto.id)
    
    return ReturnListContainerView()
        .environment(userModel)
        .environment(loanModel)
        .environment(bookModel)
        .environment(classGroupModel)
}
