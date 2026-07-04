import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出モードのContainer View（貸出タブのルート）
///
/// 本起点の3タップ貸出フローを提供します。
/// 図書一覧で本をタップすると、フォームシートが開き
/// 「だれが借りますか？」（利用者選択）→「どの枠で借りますか？」（家庭の枠確認）
/// → ✓カード の順にシートの中だけで完結します。背後の図書一覧は動きません。
/// 貸出が終わる（✓カードが消える）と、または置き去り復帰時にはシートを閉じます。
/// 返却モードで確立したパターン（カード表示中は留まり消えたら戻る・
/// 無操作15秒で置き去り復帰）を踏襲します。
struct BorrowListContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(LoanModel.self) private var loanModel
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    /// タップされた図書。非nilの間フォームシートを開く（シートの提示単位）
    @State private var selectedBook: Book?
    /// フォームシート内部の遷移パス（利用者選択→枠確認）
    @State private var sheetPath = NavigationPath()
    /// 利用者選択画面で組チップにより絞り込み中の組ID（nilなら全組）
    @State private var selectedClassGroupId: UUID?
    @State private var searchText = ""
    @State private var selectedKanaFilter: KanaGroup?
    @State private var selectedSortType: BookSortType = .title
    /// 五十音グループでセクション化された全図書データ（フィルタリング・ソート前のベース）
    @State private var bookSectionsState: BookSectionsState = .init(books: [])
    @State private var alertState = AlertState()
    @State private var successFeedback = SuccessFeedback()
    /// 貸出後、✓カードの表示が終わったらシートを閉じる（図書一覧へ戻す）ための予約フラグ
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
        NavigationStack {
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
                onSelect: openBorrowSheet(for:),
                imageURLProvider: { book in
                    book.resolvedSmallImageSource
                }
            ) { book in
                // 押せることが見た目でわかるように、行の右端は状態バッジではなく
                // 同じ形のボタンで揃える：借りられる本＝青い「借りる」（主役の操作）、
                // 貸出中＝グレーの「貸出中」（押すと返却予定日の案内シートが開く）。
                // 行全体もタップ可能なので、ボタンの外を押しても同じ動きになる
                if loanModel.isBookLent(bookId: book.id) {
                    LoanButtonView(title: "貸出中", systemImage: "book.closed", tint: .gray) {
                        openBorrowSheet(for: book)
                    }
                } else {
                    LoanButtonView(title: "借りる") {
                        openBorrowSheet(for: book)
                    }
                }
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
        .sheet(item: $selectedBook) { book in
            // 貸出中の案内だけの本は小さなフォームシートで十分（すぐ閉じられる）。
            // 200人規模の名前一覧＋組チップを載せる貸出タスクは、
            // 一回り大きいシステム標準のページシートで出す
            if loanModel.isBookLent(bookId: book.id) {
                borrowSheetContent(for: book)
                    .presentationSizing(.form)
            } else {
                borrowSheetContent(for: book)
                    .presentationSizing(.page)
            }
        }
    }
    
    /// 貸出シートの中身（利用者選択→枠確認→✓カード）
    ///
    /// 一時的な貸出タスクをシートの中だけで完結させる。
    /// ✓カードとアラートは背後の図書一覧に付けると隠れるため、必ずシート内に置く
    private func borrowSheetContent(for book: Book) -> some View {
        NavigationStack(path: $sheetPath) {
            borrowerPickScreen(for: book)
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
            // ✓カードがタイムアウトで消えたらシートを閉じる
            if wasPresented && !isPresented && isPopPendingAfterLend {
                isPopPendingAfterLend = false
                selectedBook = nil
            }
        }
    }
    
    // MARK: - Private Views
    
    /// 利用者選択画面（フォームシートの最初の画面・「だれが借りますか？」）
    ///
    /// 貸出中の図書が選ばれた場合は貸出できない理由を説明する空状態を表示する。
    @ViewBuilder
    private func borrowerPickScreen(for book: Book) -> some View {
        Group {
            if loanModel.isBookLent(bookId: book.id) {
                ContentUnavailableView(
                    "この図書は貸出中です",
                    systemImage: "book.closed",
                    description: Text(lentBookDescription(for: book))
                )
            } else {
                BorrowerListView(
                    sections: allUserSections,
                    showsOverdueFilter: false,
                    emptyStateTitle: "利用者が登録されていません",
                    emptyStateDescription: "設定画面から利用者を登録してください",
                    // 自分の組が分かっていて切り替えたい画面なので、
                    // チップはインデックスではなくフィルタとして動作させる
                    chipBehavior: .filter,
                    selectedSectionId: $selectedClassGroupId,
                    isOverdueOnly: .constant(false),
                    onSelect: { row in
                        sheetPath.append(BorrowConfirmRoute(book: book, userId: row.id))
                    }
                )
            }
        }
        .task(id: idleTicket) {
            // 無操作タイムアウト：操作のたびにidleTicketが変わり、
            // タスクが再起動して待ち時間が延長される。画面を離れると自動キャンセルされる
            try? await Task.sleep(for: Self.screenIdleTimeout)
            if Task.isCancelled { return }
            // 置き去りとみなしてシートを閉じる
            selectedBook = nil
        }
        .navigationTitle("だれが借りますか？")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // 下スワイプを知らない利用者のための明示的な閉じるボタン
                    Button {
                        selectedBook = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        #endif
    }
    
    /// 枠確認画面（シート内で利用者タップから進む先・「どの枠で借りますか？」）
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
            // 置き去りとみなしてシートを閉じる
            selectedBook = nil
        }
        .navigationTitle("どの枠で借りますか？")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // 下スワイプを知らない利用者のための明示的な閉じるボタン
                    Button {
                        selectedBook = nil
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
    ///
    /// 注意: LoanModelのgetActiveLoans()はキャッシュ更新の副作用を持ち
    /// body評価中に呼ぶと再描画ループになるため使わない（延滞表示は今回不要）
    private var allUserSections: [BorrowerListSection] {
        let allUsers = userModel.getAllUsers()
        let allUserIds = Set(allUsers.map(\.id))
        let entranceUsers = allUsers.filter { user in
            if case .guardian(let relatedChildId) = user.userType {
                return !allUserIds.contains(relatedChildId)
            }
            return true
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
    
    /// 貸出中の図書の説明文（「いつ戻るか」の目安を日付だけで知らせる）
    ///
    /// 誰が借りているかは表示しない（プライバシー配慮・IA_REVIEW 追記13）。
    /// 注意: getActiveLoans()はキャッシュ更新の副作用を持つためgetAllLoans()から絞り込む
    private func lentBookDescription(for book: Book) -> String {
        if let loan = loanModel.getAllLoans().first(where: {
            $0.bookId == book.id && !$0.isReturned
        }
        ) {
            "\(loan.dueDateText)ごろ返却予定です"
        } else {
            "返却されると貸出できるようになります"
        }
    }
    
    // MARK: - Actions
    
    /// 図書の貸出シートを開く（行タップ・「借りる」ボタンの共通入口）
    ///
    /// 一覧はプッシュ遷移させず、その図書の貸出シートを開く。
    /// 組の絞り込みも毎回リセットし、前の家庭の絞り込みを次の利用者に残さない
    private func openBorrowSheet(for book: Book) {
        sheetPath = NavigationPath()
        selectedClassGroupId = nil
        selectedBook = book
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
