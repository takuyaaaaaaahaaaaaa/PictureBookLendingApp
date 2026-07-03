import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出モードのContainer View（貸出タブのルート）
///
/// 本起点の3タップ貸出フロー（SCREEN_DESIGN_PHASE2 §4）を提供します。
/// 図書一覧 →「だれが借りますか？」（利用者選択）→「どの枠で借りますか？」（家庭の枠確認）
/// → ✓カード → 図書一覧へ戻る、の順に進みます。
/// 返却モードで確立したパターン（カード表示中は留まり消えたら戻る・
/// 無操作15秒で置き去り復帰）を踏襲します。
struct BorrowListContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(LoanModel.self) private var loanModel
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    @State private var navigationPath = NavigationPath()
    @State private var searchText = ""
    @State private var selectedKanaFilter: KanaGroup?
    @State private var selectedSortType: BookSortType = .title
    /// 五十音グループでセクション化された全図書データ（フィルタリング・ソート前のベース）
    @State private var bookSectionsState: BookSectionsState = .init(books: [])
    @State private var alertState = AlertState()
    @State private var successFeedback = SuccessFeedback()
    /// 貸出後、✓カードの表示が終わったら図書一覧へ戻るための予約フラグ
    @State private var isPopPendingAfterLend = false
    /// 選択画面の無操作タイマーのトークン（操作のたびに更新して待ち時間を延長する）
    @State private var idleTicket = 0
    /// 貸出文脈ではUndoカードを使わないためのダミー
    /// （FamilyLoanSlotsContainerViewのundoFeedbackが@Bindingのため受け皿として持つ）
    @State private var unusedUndoFeedback = UndoFeedback()
    
    /// 選択画面の無操作タイムアウト。操作がないままこの時間が経過したら、
    /// 置き去りとみなして図書一覧へ戻る
    /// （次の利用者に前の家庭の情報を見せないためのキオスク作法）
    private static let screenIdleTimeout: Duration = .seconds(15)
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            BookListView(
                sections: bookSectionsState.filter(
                    searchText: searchText,
                    kanafilter: selectedKanaFilter,
                    sortType: selectedSortType),
                searchText: $searchText,
                selectedKanaFilter: $selectedKanaFilter,
                selectedSortType: $selectedSortType,
                onEdit: { _ in },
                onDelete: { _ in },
                imageURLProvider: { book in
                    book.resolvedSmallImageSource
                }
            ) { book in
                BookStatusView(isCurrentlyLent: loanModel.isBookLent(bookId: book.id))
            }
            .navigationTitle("貸出")
            #if os(iOS)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "図書のタイトルまたは著者で検索")
            #else
                .searchable(text: $searchText, prompt: "図書のタイトルまたは著者で検索")
            #endif
            .navigationDestination(for: Book.self) { book in
                borrowerPickScreen(for: book)
            }
            .navigationDestination(for: BorrowConfirmRoute.self) { route in
                slotConfirmScreen(for: route)
            }
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .successFeedback($successFeedback)
        .onChange(of: successFeedback.isPresented) { wasPresented, isPresented in
            // カードがタイムアウトで消えたら一覧へ戻る
            if wasPresented && !isPresented && isPopPendingAfterLend {
                isPopPendingAfterLend = false
                popToRoot()
            }
        }
        .onChange(of: bookModel.books) {
            loadBookSections()
        }
        .onAppear {
            refreshData()
            loadBookSections()
        }
        .refreshable {
            refreshData()
            loadBookSections()
        }
    }
    
    // MARK: - Private Views
    
    /// 利用者選択画面（図書タップのプッシュ先・「だれが借りますか？」）
    ///
    /// 貸出中の図書が選ばれた場合は貸出できない理由を説明する空状態を表示する。
    @ViewBuilder
    private func borrowerPickScreen(for book: Book) -> some View {
        Group {
            if loanModel.isBookLent(bookId: book.id) {
                ContentUnavailableView(
                    "この図書は貸出中です",
                    systemImage: "book.closed",
                    description: Text("返却されると貸出できるようになります")
                )
            } else {
                BorrowerListView(
                    sections: allUserSections,
                    showsOverdueFilter: false,
                    emptyStateTitle: "利用者が登録されていません",
                    emptyStateDescription: "設定画面から利用者を登録してください",
                    isOverdueOnly: .constant(false),
                    onSelect: { row in
                        navigationPath.append(BorrowConfirmRoute(book: book, userId: row.id))
                    }
                )
            }
        }
        .task(id: idleTicket) {
            // 無操作タイムアウト：操作のたびにidleTicketが変わり、
            // タスクが再起動して待ち時間が延長される。画面を離れると自動キャンセルされる
            try? await Task.sleep(for: Self.screenIdleTimeout)
            if Task.isCancelled { return }
            popToRoot()
        }
        .navigationTitle("だれが借りますか？")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    /// 枠確認画面（利用者タップのプッシュ先・「どの枠で借りますか？」）
    ///
    /// 選んだ図書の要約を上部に示し、家庭の枠領域（貸出文脈）で空き枠を選ばせる。
    private func slotConfirmScreen(for route: BorrowConfirmRoute) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("『\(route.book.title)』")
                        .font(.title3.bold())
                    if let author = route.book.author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                FamilyLoanSlotsContainerView(
                    alertState: $alertState,
                    undoFeedback: $unusedUndoFeedback,
                    userId: route.userId,
                    mode: .borrowing,
                    onReturnCompleted: { _ in },
                    onBorrowSlotSelected: { slotUserId in
                        handleLend(book: route.book, userId: slotUserId)
                    }
                )
            }
            .padding()
        }
        .task(id: idleTicket) {
            // 無操作タイムアウト：操作のたびにidleTicketが変わり、
            // タスクが再起動して待ち時間が延長される。画面を離れると自動キャンセルされる
            try? await Task.sleep(for: Self.screenIdleTimeout)
            if Task.isCancelled { return }
            popToRoot()
        }
        .navigationTitle("どの枠で借りますか？")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    // MARK: - Computed Properties
    
    /// 全利用者の組セクション（利用者選択画面用・組ごとに名前順）
    ///
    /// 注意: LoanModelのgetActiveLoans()はキャッシュ更新の副作用を持ち
    /// body評価中に呼ぶと再描画ループになるため使わない（延滞表示は今回不要）
    private var allUserSections: [BorrowerListSection] {
        Dictionary(grouping: userModel.getAllUsers()) { $0.classGroupId }
            .map { classGroupId, users in
                BorrowerListSection(
                    id: classGroupId,
                    title: classGroupModel.findClassGroupById(classGroupId)?.name ?? "未分類",
                    rows:
                        users
                        .sorted { $0.name < $1.name }
                        .map { user in
                            BorrowerRowDisplay(
                                id: user.id,
                                name: user.name,
                                isGuardian: user.userType.category == .guardian,
                                isOverdue: false
                            )
                        }
                )
            }
            .sorted { $0.title < $1.title }
    }
    
    // MARK: - Actions
    
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
    
    /// 図書一覧（ルート）へ戻る（次の親子への画面の引き継ぎ）
    private func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    private func refreshData() {
        bookModel.refreshBooks()
        loanModel.refreshLoans()
        userModel.refreshUsers()
        classGroupModel.refreshClassGroups()
    }
    
    /// 図書データから基本セクションを作成・更新
    private func loadBookSections() {
        bookSectionsState = BookSectionsState(books: bookModel.books)
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
    
    // 組1つ・園児2人（うち1人に保護者を紐付け）・図書3冊（1冊は貸出中）をセットアップ
    let momo = ClassGroup(name: "もも組", ageGroup: AgeGroup.age(4), year: 2026)
    try! mockFactory.classGroupRepository.save(momo)
    
    let sakura = try! userModel.registerUser(User(name: "いとう さくら", classGroupId: momo.id))
    _ = try! userModel.registerUser(
        User(
            name: "伊藤 由美子", classGroupId: momo.id,
            userType: .guardian(relatedChildId: sakura.id)))
    _ = try! userModel.registerUser(User(name: "あおき はると", classGroupId: momo.id))
    
    let guriToGura = try! bookModel.registerBook(Book(title: "ぐりとぐら", author: "中川李枝子"))
    _ = try! bookModel.registerBook(Book(title: "だいくとおにろく", author: "松居直"))
    _ = try! bookModel.registerBook(Book(title: "はらぺこあおむし", author: "エリック・カール"))
    
    _ = try! loanModel.lendBook(bookId: guriToGura.id, userId: sakura.id)
    
    return BorrowListContainerView()
        .environment(bookModel)
        .environment(userModel)
        .environment(loanModel)
        .environment(classGroupModel)
}
