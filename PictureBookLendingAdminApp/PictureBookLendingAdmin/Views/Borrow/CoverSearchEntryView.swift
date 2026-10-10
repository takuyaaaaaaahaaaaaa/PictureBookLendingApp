import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// Readiness is checked before opening the camera; preparation never blocks books already indexed.
struct CoverSearchEntryView: View {
    @Environment(\.analytics) private var analytics
    @State private var hasTrackedRoute = false
    @State private var enteredCamera = false
    @State private var hasFinishedPreparation = false
    @Environment(BookModel.self) private var bookModel
    @Environment(\.dismiss) private var dismiss
    @State private var service = CoverRecognitionService.shared
    @State private var isSearching = false
    @State private var hasResolvedEntry = false
    let onSelect: (Book) -> Void

    init(isInitiallyReady: Bool, onSelect: @escaping (Book) -> Void) {
        _enteredCamera = State(initialValue: isInitiallyReady)
        _isSearching = State(initialValue: isInitiallyReady)
        _hasResolvedEntry = State(initialValue: isInitiallyReady)
        self.onSelect = onSelect
    }

    private var canSearch: Bool {
        service.hasPreparedBook(in: bookModel.books, isComplete: bookModel.hasLoadedBooks)
    }

    var body: some View {
        ZStack {
            if isSearching {
                CoverSearchSheet(books: bookModel.books, onSelect: onSelect)
            } else {
                NavigationStack {
                    CoverPreparationContainerView(onSearch: {
                        enteredCamera = true
                        isSearching = true
                    })
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("閉じる", systemImage: "xmark", role: .closeIfAvailable) {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: isSearching, initial: true) { _, searching in
            if searching { enteredCamera = true }
            guard !hasTrackedRoute else { return }
            hasTrackedRoute = true
            analytics.track(.coverSearchRouted(route: searching ? .ready : .preparation))
        }
        .onDisappear {
            if !enteredCamera && !hasFinishedPreparation {
                hasFinishedPreparation = true
                analytics.track(
                    .coverSearchFinished(
                        outcome: .abandoned, hadCandidates: false, noCandidates: false))
            }
        }
        .onChange(of: service.hasCheckedPreparation && bookModel.hasLoadedBooks, initial: true) {
            _, checked in
            guard checked, !hasResolvedEntry else { return }
            hasResolvedEntry = true
            if canSearch { enteredCamera = true }
            isSearching = canSearch
        }
    }
}
