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
    
    @State private var searchText = ""
    @State private var isAddSheetPresented = false
    @State private var editingBook: Book?
    @State private var isEditMode = false
    @State private var alertState = AlertState()
    @State private var selectedKanaFilter: KanaGroup?
    
    private var filteredSections: [BookSection] {
        // 検索テキストでフィルタリング
        let filteredBooks: [Book] =
            if searchText.isEmpty {
                bookModel.books
            } else {
                bookModel.books.filter { book in
                    book.title.localizedCaseInsensitiveContains(searchText)
                        || book.author.localizedCaseInsensitiveContains(searchText)
                }
            }

        // 五十音グループごとに分類
        let groupedBooks = Dictionary(grouping: filteredBooks) { book -> KanaGroup in
            return book.kanaGroup ?? .other
        }
        
        // セクションを作成
        var sections = groupedBooks.compactMap { (kanaGroup, books) in
            BookSection(kanaGroup: kanaGroup, books: books.sorted { $0.title < $1.title })
        }
        
        // 五十音順にソート
        sections.sort { $0.kanaGroup.sortOrder < $1.kanaGroup.sortOrder }
        
        // 選択されたフィルターがある場合は該当セクションのみ表示
        if let selectedKanaFilter = selectedKanaFilter {
            return sections.filter { $0.kanaGroup == selectedKanaFilter }
        }
        
        return sections
    }
    
    var body: some View {
        BookListView(
            sections: filteredSections,
            searchText: $searchText,
            selectedKanaFilter: $selectedKanaFilter,
            isEditMode: isEditMode,
            onSelect: handleSelectBook,
            onEdit: handleEditBook,
            onDelete: handleDeleteBooks
        ) { book in
            BookStatusView(isCurrentlyLent: loanModel.isBookLent(bookId: book.id))
        }
        .navigationTitle("絵本管理")
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
                    Label("絵本を追加", systemImage: "plus")
                }
            }
        }
        #if os(macOS)
            .sheet(isPresented: $isAddSheetPresented) {
                BookFormContainerView(
                    mode: .add,
                    onSave: { _ in
                        // 追加成功時にシートを閉じる処理は既にContainerView内で実行される
                    }
                )
            }
            .sheet(item: $editingBook) { book in
                BookFormContainerView(
                    mode: .edit(book),
                    onSave: { _ in
                        // 編集成功時にシートを閉じる処理は既にContainerView内で実行される
                    }
                )
            }
        #else
            .fullScreenCover(isPresented: $isAddSheetPresented) {
                BookFormContainerView(
                    mode: .add,
                    onSave: { _ in
                        // 追加成功時にシートを閉じる処理は既にContainerView内で実行される
                    }
                )
            }
            .fullScreenCover(item: $editingBook) { book in
                BookFormContainerView(
                    mode: .edit(book),
                    onSave: { _ in
                        // 編集成功時にシートを閉じる処理は既にContainerView内で実行される
                    }
                )
            }
        #endif
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .onAppear {
            bookModel.refreshBooks()
            loanModel.refreshLoans()
        }
        .refreshable {
            bookModel.refreshBooks()
            loanModel.refreshLoans()
        }
    }
    
    // MARK: - Actions
    
    private func handleSelectBook(_ book: Book) {
        // 絵本詳細画面に遷移（NavigationLinkで自動的に処理される）
    }
    
    private func handleEditBook(_ book: Book) {
        editingBook = book
    }
    
    private func handleDeleteBooks(at offsets: IndexSet) {
        // セクション内での削除処理はより複雑になるため、
        // 現在は削除機能を無効化します
        // TODO: セクション対応の削除処理を実装
        alertState = .info("セクション表示では削除機能は現在無効です")
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
