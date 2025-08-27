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
    @State private var selectedSortType: BookSortType = .title
    
    private var filteredSections: [BookSection] {
        // 検索テキストでフィルタリング
        let filteredBooks: [Book] =
            if searchText.isEmpty {
                bookModel.books
            } else {
                bookModel.books.filter { book in
                    book.title.localizedCaseInsensitiveContains(searchText)
                        || book.author?.localizedCaseInsensitiveContains(searchText) == true
                }
            }

        // 五十音グループごとに分類
        let groupedBooks = Dictionary(grouping: filteredBooks) { book -> KanaGroup in
            return book.kanaGroup ?? .other
        }
        
        // セクションを作成（ソート指定に基づいて）
        var sections = groupedBooks.compactMap { (kanaGroup, books) in
            let sortedBooks: [Book]
            switch selectedSortType {
            case .title:
                sortedBooks = books.sorted { $0.title < $1.title }
            case .managementNumber:
                sortedBooks = books.sorted { book1, book2 in
                    // 管理番号がない場合は最後に配置
                    switch (book1.managementNumber, book2.managementNumber) {
                    case (nil, nil):
                        return book1.title < book2.title
                    case (nil, _):
                        return false
                    case (_, nil):
                        return true
                    case (let num1?, let num2?):
                        return num1 < num2
                    }
                }
            }
            return BookSection(kanaGroup: kanaGroup, books: sortedBooks)
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
            selectedSortType: $selectedSortType,
            isEditMode: isEditMode,
            onEdit: handleEditBook,
            onDelete: handleDeleteBook
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
