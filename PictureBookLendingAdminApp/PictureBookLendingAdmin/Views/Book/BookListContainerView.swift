import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 絵本一覧のContainer View
///
/// 全絵本（貸出可能・貸出中を含む）を表示し、
/// 状態に応じて貸出・返却ボタンを提供します。
struct BookListContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(LoanModel.self) private var loanModel
    
    @State private var searchText = ""
    @State private var isSettingsPresented = false
    @State private var isEditMode = false
    @State private var isAddSheetPresented = false
    @State private var isBulkAddSheetPresented = false
    @State private var editingBook: Book?
    @State private var alertState = AlertState()
    @State private var selectedKanaFilter: KanaGroup?
    @State private var selectedSortType: BookSortType = .title
    /// 五十音グループでセクション化された全絵本データ（フィルタリング・ソート前のベース）
    @State private var bookSections: [BookSection] = []
    
    /// フィルタリング・ソート済みの絵本セクション
    private var filteredBookSections: [BookSection] {
        // 1. フィルタリング
        let filteredSections = BookSection.filtered(
            sections: bookSections,
            searchText: searchText,
            selectedKanaFilter: selectedKanaFilter
        )
        
        // 2. ソート
        return BookSection.sorted(sections: filteredSections, by: selectedSortType)
    }
    
    var body: some View {
        BookListView(
            sections: filteredBookSections,
            searchText: $searchText,
            selectedKanaFilter: $selectedKanaFilter,
            selectedSortType: $selectedSortType,
            isEditMode: isEditMode,
            onEdit: handleEditBook,
            onDelete: handleDeleteBook
        ) { book in
            if isEditMode {
                BookStatusView(isCurrentlyLent: loanModel.isBookLent(bookId: book.id))
            } else {
                LoanActionContainerButton(bookId: book.id)
            }
        }
        #if os(iOS)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "絵本のタイトルまたは著者で検索")
        #else
            .searchable(
                text: $searchText,
                prompt: "絵本のタイトルまたは著者で検索")
        #endif
        .navigationTitle("絵本")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // 設定ボタン
                // TODO: iOS26 beta6のバグで以下が効かない
                //SettingContainerButton()
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
        .navigationDestination(for: Book.self) { book in
            BookDetailContainerView(book: book)
        }
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
    
    // MARK: - Actions
    
    /// 絵本データから基本セクションを作成・更新
    private func loadBookSections() {
        bookSections = BookSection.createSections(from: bookModel.books)
    }
    
    private func handleEditBook(_ book: Book) {
        editingBook = book
    }
    
    private func handleDeleteBook(_ book: Book) {
        do {
            _ = try bookModel.deleteBook(book.id)
        } catch {
            alertState = .error("絵本の削除に失敗しました", message: "\(error.localizedDescription)")
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
    let userModel = UserModel(repository: mockFactory.userRepository)
    let loanModel = LoanModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository,
        loanSettingsRepository: mockFactory.loanSettingsRepository
    )
    
    return BookListContainerView()
        .environment(bookModel)
        .environment(loanModel)
        .environment(userModel)
}
