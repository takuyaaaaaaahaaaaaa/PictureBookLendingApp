import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 設定画面用の絵本一覧Container View
///
/// 絵本の管理機能に特化し、貸出ボタンの代わりに貸出状況を表示します。
struct SettingsBookListContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(LoanModel.self) private var loanModel
    
    /// 図書一覧の絞り込み状態（検索テキスト・五十音フィルタ。両者は排他制御される）
    @State private var filterState = BookListFilterState()
    @State private var isAddSheetPresented = false
    @State private var editingBook: Book?
    @State private var isEditMode = false
    @State private var alertState = AlertState()
    @State private var deleteConfirmationState = AlertState()
    /// 削除の確認待ちの図書
    ///
    /// 一覧の削除は1冊ずつ通知されるが、編集モードの複数削除では同じ実行ループ内で
    /// 続けて呼ばれるため、単一の図書ではなく配列で受けて1回の確認にまとめる
    @State private var booksToDelete: [Book] = []
    @State private var selectedSortType: BookSortType = .title
    /// 管理業務では著者・管理番号・貸出状況の情報密度が必要なためリストを既定にする
    /// （貸出タブは実物の表紙との照合が主タスクなので棚表示既定。使い分けの経緯はissue #179）
    @State private var displayMode: BookDisplayMode = .list
    
    var body: some View {
        BookListView(
            sections: bookSections.filter(
                searchText: filterState.searchText,
                kanafilter: filterState.selectedKanaFilter,
                sortType: selectedSortType),
            searchText: searchTextBinding,
            selectedKanaFilter: kanaFilterBinding,
            selectedSortType: $selectedSortType,
            displayMode: $displayMode,
            isEditMode: isEditMode,
            onEdit: handleEditBook,
            onDelete: handleDeleteBook,
            imageURLProvider: { book in
                book.resolvedSmallImageSource
            }
        ) { book in
            BookStatusView(isCurrentlyLent: loanModel.isBookLent(bookId: book.id))
        }
        .navigationTitle("図書管理")
        #if os(iOS)
            .searchable(
                text: searchTextBinding,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "図書のタイトルまたは著者で検索")
        #else
            .searchable(text: searchTextBinding, prompt: "図書のタイトルまたは著者で検索")
        #endif
        .navigationDestination(for: Book.self) { book in
            BookDetailContainerView(book: book)
        }
        .toolbar {
            ToolbarItem {
                Button(isEditMode ? "編集モード完了" : "編集モード") {
                    isEditMode.toggle()
                }
            }
            
            ToolbarSpacer(.fixed)
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isAddSheetPresented = true
                }) {
                    Label("図書を追加", systemImage: "plus")
                }
            }
        }
        #if os(macOS)
            .sheet(isPresented: $isAddSheetPresented) {
                BookFormContainerView(mode: .add)
            }
            .sheet(item: $editingBook) { book in
                BookFormContainerView(mode: .edit(book))
            }
        #else
            .fullScreenCover(isPresented: $isAddSheetPresented) {
                BookFormContainerView(mode: .add)
            }
            .fullScreenCover(item: $editingBook) { book in
                BookFormContainerView(mode: .edit(book))
            }
        #endif
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .alert(deleteConfirmationState.title, isPresented: $deleteConfirmationState.isPresented) {
            Button("削除", role: .destructive) {
                executeDelete()
            }
            Button("キャンセル", role: .cancel) {
                booksToDelete = []
            }
        } message: {
            Text(deleteConfirmationState.message)
        }
        .refreshable {
            bookModel.refreshBooks()
            loanModel.refreshLoans()
        }
    }
    
    // MARK: - Computed Properties
    
    /// 五十音グループでセクション化された全絵本データ（フィルタリング・ソート前のベース）
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
    private var kanaFilterBinding: Binding<KanaGroup?> {
        Binding(
            get: { filterState.selectedKanaFilter },
            set: { filterState.setKanaFilter($0) }
        )
    }
    
    // MARK: - Actions
    
    private func handleEditBook(_ book: Book) {
        editingBook = book
    }
    
    /// 削除の確認
    ///
    /// 貸出中の図書は削除と同時に自動返却されるため、貸出の有無にかかわらず必ず確認を挟む。
    /// 確認なしに削除すると、返却する手段のない貸出（返却タブに借用者の名前だけ残り、
    /// 開いても枠が出ないため返せない）が生まれてしまう
    private func handleDeleteBook(_ book: Book) {
        // 編集モードの複数削除では1冊ずつ続けて呼ばれるため、貯めてから1回の確認にまとめる
        if !booksToDelete.contains(where: { $0.id == book.id }) {
            booksToDelete.append(book)
        }
        
        deleteConfirmationState = AlertState(
            isPresented: true,
            title: "図書の削除",
            message: BookDeletionMessage.make(
                targetTitles: booksToDelete.map(\.title),
                autoReturningLoans: autoReturningLoans(of: booksToDelete).map {
                    BookDeletionMessage.AutoReturningLoan(
                        bookTitle: $0.book.title,
                        userName: $0.loan.user.name
                    )
                }
            )
        )
    }
    
    private func executeDelete() {
        let targetBooks = booksToDelete
        booksToDelete = []
        deleteConfirmationState = AlertState()
        guard !targetBooks.isEmpty else { return }
        
        // 途中で失敗しても、すでに返却済みにした冊数は利用者に伝える必要がある
        var returnedCount = 0
        do {
            // 貸出中の図書は先に返却する
            // （先に図書を削除すると、返却操作ができない貸出だけが残ってしまう）
            for entry in autoReturningLoans(of: targetBooks) {
                _ = try loanModel.returnBook(loanId: entry.loan.id)
                returnedCount += 1
            }
            
            for book in targetBooks {
                _ = try bookModel.deleteBook(book.id)
            }
        } catch {
            let returnedNote =
                returnedCount > 0 ? "\n貸出中だった図書\(returnedCount)冊は返却済みになっています。" : ""
            alertState = .error(
                "図書の削除に失敗しました", message: "\(error.localizedDescription)\(returnedNote)")
        }
    }
    
    /// 削除に伴って自動返却される貸出（図書とその貸出の組）
    ///
    /// 運用上は1冊につき1件だが、取りこぼすと返却する手段のない貸出が残るため全件を対象にする
    private func autoReturningLoans(of books: [Book]) -> [(book: Book, loan: Loan)] {
        books.flatMap { book in
            loanModel.getBookActiveLoans(bookId: book.id).map { (book: book, loan: $0) }
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    
    // プレビュー用のサンプルデータを追加
    let book1 = Book(title: "はらぺこあおむし", author: "エリック・カール")
    let book2 = Book(title: "ぐりとぐら", author: "中川李枝子")
    _ = try? mockFactory.bookRepository.save(book1)
    _ = try? mockFactory.bookRepository.save(book2)
    
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let loanModel = LoanModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository,
        loanSettingsRepository: mockFactory.loanSettingsRepository
    )
    
    return SettingsBookListContainerView()
        .environment(bookModel)
        .environment(loanModel)
}
