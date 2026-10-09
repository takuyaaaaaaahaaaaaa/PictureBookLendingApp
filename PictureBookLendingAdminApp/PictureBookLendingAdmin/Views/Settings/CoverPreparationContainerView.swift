import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

struct CoverPreparationContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @State private var service = CoverRecognitionService.shared
    @State private var isRetryRequested = false
    var onSearch: (() -> Void)? = nil

    private var canSearch: Bool {
        service.hasPreparedBook(in: bookModel.books, isComplete: bookModel.hasLoadedBooks)
    }

    private var status: String {
        if !bookModel.hasLoadedBooks { return "図書一覧を確認しています" }
        if bookModel.books.isEmpty { return "登録されている図書がありません" }
        if let error = service.preparationError { return error }
        if !service.hasCheckedPreparation { return "準備状況を確認しています" }
        return "準備済み \(service.preparedCount)冊・未処理 \(service.pendingCount)冊"
    }

    private var explanation: String {
        if !bookModel.hasLoadedBooks {
            return "図書一覧の読み込みが完了していません。続く場合はこの画面を閉じて読み込み状況を確認してください。"
        }
        if bookModel.books.isEmpty { return "設定の図書管理から本を登録してください。" }
        if service.isPreparing {
            return canSearch ? "残りの表紙を準備しています。準備済みの本は検索できます。" : "表紙を準備しています。画面を閉じて他の操作を続けられます。"
        }
        if !service.hasCheckedPreparation && service.preparationError == nil {
            return "保存済みの検索データを確認しています。"
        }
        if canSearch { return "準備済みの本を表紙から探せます。未処理の本は画像や通信状況を確認して再試行してください。" }
        return "検索できる表紙がまだありません。表紙画像や通信状況を確認して、再試行してください。"
    }

    var body: some View {
        CoverPreparationView(
            status: status, explanation: explanation,
            isBusy: service.isPreparing || isRetryRequested,
            canRetry: bookModel.hasLoadedBooks && !bookModel.books.isEmpty
                && !service.isPreparing && !isRetryRequested
                && (service.pendingCount > 0 || !service.hasCheckedPreparation
                    || service.preparationError != nil),
            canSearch: canSearch,
            onRetry: {
                guard !isRetryRequested, !service.isPreparing else { return }
                isRetryRequested = true
                Task {
                    await service.prepare(
                        books: bookModel.books, isComplete: bookModel.hasLoadedBooks)
                    isRetryRequested = false
                }
            },
            onSearch: onSearch
        )
    }
}
