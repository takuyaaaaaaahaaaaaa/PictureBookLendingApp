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
    @State private var selectedSortType: BookSortType = .title
    /// 五十音グループでセクション化された全絵本データ（フィルタリング・ソート前のベース）
    @State private var bookSectionsState: BookSectionsState = .init(books: [])
    
    var body: some View {
        BookListView(
            sections: bookSectionsState.filter(
                searchText: filterState.searchText,
                kanafilter: filterState.selectedKanaFilter,
                sortType: selectedSortType),
            searchText: searchTextBinding,
            selectedKanaFilter: kanaFilterBinding,
            selectedSortType: $selectedSortType,
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
        .onChange(of: bookModel.books) {
            loadBookSections()
        }
        .onAppear {
            bookModel.refreshBooks()
            loanModel.refreshLoans()
            loadBookSections()
        }
        .refreshable {
            bookModel.refreshBooks()
            loanModel.refreshLoans()
            loadBookSections()
        }
    }
    
    // MARK: - Computed Properties
    
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
    
    /// 絵本データから基本セクションを作成・更新
    private func loadBookSections() {
        bookSectionsState = BookSectionsState(books: bookModel.books)
    }
    
    private func handleEditBook(_ book: Book) {
        editingBook = book
    }
    
    private func handleDeleteBook(_ book: Book) {
        do {
            _ = try bookModel.deleteBook(book.id)
        } catch {
            alertState = .error("図書の削除に失敗しました", message: "\(error.localizedDescription)")
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
