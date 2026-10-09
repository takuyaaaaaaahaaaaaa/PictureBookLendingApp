import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// Readiness is checked before opening the camera; preparation never blocks books already indexed.
struct CoverSearchEntryView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(\.dismiss) private var dismiss
    @State private var service = CoverRecognitionService.shared
    @State private var isSearching = false
    @State private var hasResolvedEntry = false
    let onSelect: (Book) -> Void

    init(isInitiallyReady: Bool, onSelect: @escaping (Book) -> Void) {
        _isSearching = State(initialValue: isInitiallyReady)
        _hasResolvedEntry = State(initialValue: isInitiallyReady)
        self.onSelect = onSelect
    }

    private var canSearch: Bool {
        service.hasPreparedBook(in: bookModel.books, isComplete: bookModel.hasLoadedBooks)
    }

    var body: some View {
        Group {
            if isSearching {
                CoverSearchSheet(books: bookModel.books, onSelect: onSelect)
            } else {
                NavigationStack {
                    CoverPreparationContainerView(onSearch: { isSearching = true })
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("閉じる") { dismiss() }
                            }
                        }
                }
            }
        }
        .onChange(of: service.hasCheckedPreparation && bookModel.hasLoadedBooks, initial: true) {
            _, checked in
            guard checked, !hasResolvedEntry else { return }
            hasResolvedEntry = true
            isSearching = canSearch
        }
    }
}
