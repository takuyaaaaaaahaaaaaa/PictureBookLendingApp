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
/// → ✓カード の順にシートの中だけで完結します（シートの中身は`BorrowSheetContainerView`）。
/// 背後の図書一覧は動きません。
/// 貸出が終わる（✓カードが消える）と、または置き去り復帰時にはシートを閉じます。
/// 返却モードで確立したパターン（カード表示中は留まり消えたら戻る・
/// 無操作15秒で置き去り復帰）を踏襲します。
struct BorrowListContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(LoanModel.self) private var loanModel
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(\.analytics) private var analytics
    
    /// タップされた図書と開いた時点の貸出状態。非nilの間フォームシートを開く（シートの提示単位）
    ///
    /// 「貸出中だったか」はitemに焼き込んだスナップショットで持つ。
    /// 別の@Stateに分けると、シート提示の瞬間に古いビュー値で評価されて
    /// 図書と貸出状態がズレることがある（貸出直後に同じ図書を開き直すと
    /// 貸出中なのに利用者選択が出る）。itemと一体なら必ず一致する。
    /// ライブでloanModel.isBookLent(bookId:)を見ないのは従来どおり：貸出が成立した
    /// その瞬間に値が反転し、シートの土台（フォームシート/ページシートの分岐、
    /// 案内画面/名前一覧の分岐）ごと作り直されて✓カードが一瞬で消えてしまうため
    @State private var borrowSheetContext: BorrowSheetContext?
    /// 図書一覧の絞り込み状態（検索テキスト・五十音フィルタ。両者は排他制御される）
    @State private var filterState = BookListFilterState()
    /// 図書一覧をトップへ戻すトリガ（貸出完了ごとにインクリメント）
    @State private var scrollToTopTrigger = 0
    @State private var selectedSortType: BookSortType = .title
    @State private var displayMode: BookDisplayMode = .shelf
    /// 設定画面表示状態
    @State private var isSettingsPresented = false
    /// 直近に記録した検索テキスト（トリム後。未記録ならnil）
    ///
    /// `.task`はタブを行き来して画面が再表示されるたびに走り直すため、
    /// これがないと同じ検索が何度も記録され0件ヒット率が歪む
    @State private var lastTrackedSearchText: String?
    /// 一覧の表示の大きさ（「大きく表示」フローティングボタンのトグル状態）。
    /// 文字が見えづらい利用者は毎回見えづらいため、一時的なモードではなく
    /// アプリを再起動しても維持される永続設定にする
    @AppStorage("borrowListDisplayScale") private var displayScale: BookDisplayScale = .standard
    
    /// 「大きく表示」フローティングボタンの画面端からの余白
    private static let displayScaleButtonPadding: CGFloat = 24
    
    /// 検索イベントの記録設定
    private enum SearchTracking {
        /// 入力が止まった（検索が確定した）とみなすまでの待ち時間。
        /// 1文字打つたびに記録すると0件ヒット率が入力途中で水増しされるため置く
        static let debounce: Duration = .milliseconds(800)
    }
    
    var body: some View {
        NavigationStack {
            BookListView(
                sections: bookSections.filter(
                    searchText: filterState.searchText,
                    kanafilter: filterState.selectedKanaFilter,
                    sortType: selectedSortType),
                searchText: searchTextBinding,
                selectedKanaFilter: kanaFilterBinding,
                // 貸出完了ごとに一覧を先頭へ戻す（次の貸出への引き継ぎ）
                scrollToTopTrigger: scrollToTopTrigger,
                selectedSortType: $selectedSortType,
                displayMode: $displayMode,
                displayScale: displayScale,
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
                    RowActionButton(title: "貸出中", systemImage: "book.closed", tint: .gray) {
                        openBorrowSheet(for: book)
                    }
                } else {
                    RowActionButton(title: "借りる") {
                        openBorrowSheet(for: book)
                    }
                }
            }
            // 「大きく表示」フローティングボタン。文字が見えづらい利用者が
            // 最初に見つけられるよう、表示メニューの中ではなく常時見える位置に置く。
            // overlayではなくsafeAreaInsetにすることで一覧側に下端の余白が効き、
            // 最下段のセル・「借りる」ボタンがボタンの下に隠れたままにならない
            .safeAreaInset(edge: .bottom, alignment: .trailing) {
                BookDisplayScaleToggleButton(scale: $displayScale)
                    .padding(Self.displayScaleButtonPadding)
            }
            .navigationTitle("貸出")
            #if os(iOS)
                .searchable(
                    text: searchTextBinding,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "図書のタイトルまたは著者で検索")
            #else
                .searchable(text: searchTextBinding, prompt: "図書のタイトルまたは著者で検索")
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("設定", systemImage: "gearshape") {
                        isSettingsPresented = true
                    }
                }
            }
            #if os(macOS)
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsContainerView()
                }
            #else
                .fullScreenCover(isPresented: $isSettingsPresented) {
                    SettingsContainerView()
                }
            #endif
        }
        .refreshable {
            refreshData()
        }
        // 検索の質（0件ヒット・あいまい検索の発動）を記録する。
        // 入力が変わるたびにタスクごと作り直されるため、手が止まったときだけ残る
        .task(id: filterState.searchText) {
            await trackBookSearch()
        }
        .sheet(item: $borrowSheetContext) { context in
            // 貸出中の案内だけの本は小さなフォームシートで十分（すぐ閉じられる）。
            // 200人規模の名前一覧＋組チップを載せる貸出タスクは、
            // 一回り大きいシステム標準のページシートで出す。
            // 判定はitemに焼き込んだスナップショットを使う（理由は`borrowSheetContext`参照）
            if context.isAlreadyLent {
                borrowSheet(for: context)
                    .presentationSizing(.form)
            } else {
                borrowSheet(for: context)
                    .presentationSizing(.page)
            }
        }
    }
    
    /// 貸出シート（子Container）。シート内フローの状態はすべて子の@Stateが持つ。
    ///
    /// シート表示ごとに子が生成・破棄されるため、遷移パスや組の絞り込みは
    /// 毎回初期値から始まる（親側での手動リセットは不要）。
    private func borrowSheet(for context: BorrowSheetContext) -> some View {
        BorrowSheetContainerView(
            context: context,
            onClose: { borrowSheetContext = nil },
            onLendCompleted: handleLendCompleted
        )
    }
    
    // MARK: - Computed Properties
    
    /// 五十音グループでセクション化された全図書データ（フィルタリング・ソート前のベース）
    ///
    /// `bookModel.books`から都度導出する。値型なので手動同期（onChange/onAppear）は不要。
    private var bookSections: BookSections {
        BookSections(books: bookModel.books)
    }
    
    /// 検索テキストのバインディング（書き込みはStateの排他制御メソッドを経由させる）
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { filterState.searchText },
            set: { filterState.updateSearchText($0) }
        )
    }
    
    /// 五十音フィルタのバインディング（書き込みはStateの排他制御メソッドを経由させる）
    ///
    /// 五十音チップは検索テキストをクリアするため、先に未記録の検索を確定させる
    /// （クリア後では`.task(id:)`がキャンセルされ、その検索が記録されないまま消える）
    private var kanaFilterBinding: Binding<KanaGroup?> {
        Binding(
            get: { filterState.selectedKanaFilter },
            set: {
                flushPendingBookSearch()
                filterState.setKanaFilter($0)
            }
        )
    }
    
    /// いま図書をどうやって見つけたか（貸出フロー開始の記録用）
    ///
    /// 検索と五十音は排他制御されているため同時には成立しない。
    /// どちらも使っていなければ、一覧の見た目（棚表示かどうか）で見分ける。
    /// `flushPendingBookSearch`と同じくトリム後の文字列で判定する
    /// （揃えないと、空白のみの検索で`find_method: search`だけが記録され
    /// 対応する`book_search_performed`が発火しない食い違いが起きる）
    private var currentBookFindMethod: AnalyticsEvent.BookFindMethod {
        if !filterState.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            .search
        } else if filterState.selectedKanaFilter != nil {
            .kanaIndex
        } else if displayMode == .shelf {
            .shelf
        } else {
            .scroll
        }
    }
    
    // MARK: - Actions
    
    /// 図書の貸出シートを開く（行タップ・「借りる」ボタンの共通入口）
    ///
    /// 一覧はプッシュ遷移させず、その図書の貸出シートを開く。
    /// シート内フローの状態は子Container（`BorrowSheetContainerView`）の@Stateに任せるため、
    /// ここでは提示単位（図書＋貸出状態のスナップショット）を差し込むだけでよい。
    private func openBorrowSheet(for book: Book) {
        flushPendingBookSearch()
        
        let isAlreadyLent = loanModel.isBookLent(bookId: book.id)
        // 貸出中の案内シートは貸出フローの開始ではないため記録しない
        if !isAlreadyLent {
            analytics.track(.borrowFlowStarted(findMethod: currentBookFindMethod))
        }
        borrowSheetContext = BorrowSheetContext(book: book, isAlreadyLent: isAlreadyLent)
    }
    
    /// デバウンス待ちの検索をその場で確定させる（図書タップ・五十音チップの共通前処理）
    ///
    /// デバウンスの待ち時間より早く次の操作をした場合、その検索は記録されないまま
    /// 終わってしまう。「探せた検索」ほど早く次の操作へ進むため、放置すると
    /// 0件ヒット率が実態より高く出る。ここで先に確定させて取りこぼしを防ぐ
    private func flushPendingBookSearch() {
        let trimmedText = filterState.searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return }
        trackBookSearchIfUnrecorded(trimmedText: trimmedText)
    }
    
    /// 検索の確定（デバウンス後）を利用ログに記録する
    ///
    /// 待っている間に検索テキストが変われば`.task(id:)`ごとキャンセルされ、
    /// 入力途中の状態は記録されない
    private func trackBookSearch() async {
        let trimmedText = filterState.searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else {
            // 検索をやめた（クリアした）ら、次に同じ語を打ち直したときは別の検索として扱う
            lastTrackedSearchText = nil
            return
        }
        
        try? await Task.sleep(for: SearchTracking.debounce)
        if Task.isCancelled { return }
        
        trackBookSearchIfUnrecorded(trimmedText: trimmedText)
    }
    
    /// まだ記録していない検索テキストであれば記録する
    ///
    /// 検索文字列そのものは載せず、文字数と結果の件数だけを残す
    /// （docs/ANALYTICS_DESIGN.md 大原則2）。
    /// 同じテキストの二重記録を避けるため、記録済みのテキストを覚えておく
    private func trackBookSearchIfUnrecorded(trimmedText: String) {
        guard lastTrackedSearchText != trimmedText else { return }
        
        let outcome = bookSections.filterOutcome(
            searchText: filterState.searchText,
            kanafilter: filterState.selectedKanaFilter,
            sortType: selectedSortType
        )
        analytics.track(
            .bookSearchPerformed(
                queryLength: trimmedText.count,
                resultCount: outcome.bookCount,
                isFuzzyTriggered: outcome.isFuzzyFallback,
                isZeroHit: outcome.bookCount == 0
            )
        )
        lastTrackedSearchText = trimmedText
    }
    
    /// 貸出完了（✓カードが消えた）ときの後始末。
    ///
    /// シートを閉じ、次の貸出のために絞り込みを解除して図書一覧を先頭へ戻す
    private func handleLendCompleted() {
        borrowSheetContext = nil
        filterState.reset()
        scrollToTopTrigger += 1
    }
    
    private func refreshData() {
        bookModel.refreshBooks()
        loanModel.refreshLoans()
        userModel.refreshUsers()
        classGroupModel.refreshClassGroups()
    }
}

/// 貸出シートの提示単位（選んだ図書＋開いた時点の貸出状態のスナップショット）
///
/// 貸出状態を図書と同じitemに焼き込むことで、シート提示時に両者がズレないことを保証する
struct BorrowSheetContext: Identifiable {
    let book: Book
    let isAlreadyLent: Bool
    
    var id: UUID { book.id }
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
