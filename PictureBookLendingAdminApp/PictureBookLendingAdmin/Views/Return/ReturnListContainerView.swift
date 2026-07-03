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
    @State private var alertState = AlertState()
    @State private var undoFeedback = UndoFeedback()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            BorrowerListView(
                sections: filteredSections,
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
                onReturnCompleted: handleReturnCompleted,
                onBorrowSlotSelected: { _ in }
            )
            .padding()
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
    
    /// 返却完了時：自動で一覧に戻る（次の親子へ）
    private func handleReturnCompleted() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    /// 返却の取り消し（Undoカードの「元に戻す」）
    private func handleUndoReturn() {
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
