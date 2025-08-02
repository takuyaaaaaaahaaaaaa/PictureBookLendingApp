import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftData
import SwiftUI

/// 絵本検索・登録のContainer View
///
/// RegisterModelと連携してタイトル・著者検索による絵本登録機能を提供します。
/// ビジネスロジック、状態管理、データ永続化を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct BookSearchContainerView: View {
    
    @State private var registerModel: RegisterModel
    @State private var alertState = AlertState()
    
    init() {
        // 依存関係を初期化
        let repositoryFactory = SwiftDataRepositoryFactory.shared
        let gateway = repositoryFactory.makeBookSearchGateway()
        let normalizer = GoogleBooksOptimizedNormalizer()
        let repository = repositoryFactory.makeBookRepository()
        self._registerModel = State(
            initialValue: RegisterModel(
                gateway: gateway,
                normalizer: normalizer,
                repository: repository
            ))
    }
    
    var body: some View {
        BookSearchView(
            searchTitle: Binding(
                get: { registerModel.searchTitle },
                set: { registerModel.searchTitle = $0 }
            ),
            searchAuthor: Binding(
                get: { registerModel.searchAuthor },
                set: { registerModel.searchAuthor = $0 }
            ),
            canSearch: registerModel.canSearch,
            isSearching: registerModel.isSearching,
            searchError: registerModel.searchError,
            searchResults: registerModel.searchResults,
            selectedResult: registerModel.selectedResult,
            onResultSelected: registerModel.selectSearchResult,
            isManualEntryMode: registerModel.isManualEntryMode,
            manualBook: registerModel.manualBook,
            onManualBookChanged: registerModel.updateManualBook,
            onSearch: handleSearch,
            onClearResults: registerModel.clearSearchResults,
            onSwitchToManualEntry: registerModel.switchToManualEntry,
            onSwitchToSearchResults: registerModel.switchToSearchResults,
            onRegister: handleRegister,
            canRegister: registerModel.canRegister,
            isRegistering: registerModel.isRegistering,
            registrationError: registerModel.registrationError
        )
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleSearch() {
        do {
            try registerModel.searchBooks()
        } catch {
            alertState = AlertState(
                isPresented: true,
                title: "検索エラー",
                message: "検索中にエラーが発生しました: \(error.localizedDescription)"
            )
        }
    }
    
    private func handleRegister() {
        do {
            let _ = try registerModel.registerBook()
            showSuccessAlert()
        } catch {
            alertState = AlertState(
                isPresented: true,
                title: "登録エラー",
                message: "絵本の登録中にエラーが発生しました: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func showSuccessAlert() {
        alertState = AlertState(
            isPresented: true, title: "登録完了",
            message: "絵本が正常に登録されました。"
        )
    }
}

extension RegisterModel {
    static func stub() -> RegisterModel {
        RegisterModel(
            gateway: GoogleBookSearchGateway(),
            normalizer: GoogleBooksOptimizedNormalizer(),
            repository: DummyBookRepository()
        )
    }
}

private struct DummyBookRepository: BookRepositoryProtocol {
    func save(_ book: Book) throws -> Book {
        return book
    }
    
    func fetchAll() throws -> [Book] {
        return []
    }
    
    func findById(_ id: UUID) throws -> Book? {
        return nil
    }
    
    func update(_ book: Book) throws -> Book {
        return book
    }
    
    func delete(_ id: UUID) throws -> Bool {
        return true
    }
}

#Preview {
    NavigationStack {
        BookSearchContainerView()
    }
}
