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
    @State private var alertState = AlertState()
    @State private var selectedKanaFilter: KanaGroup?
    
    private var filteredSections: [BookSection] {
        // 全絵本を表示（貸出可能・貸出中を含む）
        let allBooks = bookModel.books
        
        // 検索テキストでフィルタリング
        let filteredBooks: [Book] =
            if searchText.isEmpty {
                allBooks
            } else {
                allBooks.filter { book in
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
            isEditMode: false,
            onSelect: handleSelectBook,
            onEdit: { _ in },  // 編集モードオフなので使用されない
            onDelete: { _ in }  // 編集モードオフなので削除不可
        ) { book in
            LoanActionContainerButton(bookId: book.id)
        }
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
        .onAppear {
            bookModel.refreshBooks()
        }
        .refreshable {
            bookModel.refreshBooks()
        }
    }
    
    // MARK: - Actions
    
    private func handleSelectBook(_ book: Book) {
        // 絵本詳細画面に遷移（NavigationLinkで自動的に処理される）
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
