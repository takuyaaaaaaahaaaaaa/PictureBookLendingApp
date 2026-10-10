import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

/// 絵本フォームのContainer View
///
/// ビジネスロジック、状態管理、データ永続化を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct BookFormContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(\.dismiss) private var dismiss

    let mode: BookFormMode
    var onSave: ((Book) -> Void)? = nil

    @State private var book: Book
    @State private var alertState = AlertState()
    @State private var isConfirmationPresented = false
    @State private var isDuplicateConfirmationPresented = false
    @State private var duplicatedBook: Book?
    @State private var isCameraPresented = false
    @State private var capturedPhoto: UIImage?
    @State private var adjustingExistingPhoto = false
    @State private var draftImageFiles: Set<String> = []
    @State private var isSaving = false
    @State private var savedBookAwaitingClose: Book?

    init(mode: BookFormMode, onSave: ((Book) -> Void)? = nil) {
        self.mode = mode
        self.onSave = onSave

        // 初期値を設定
        switch mode {
        case .add:
            self._book = State(initialValue: Book(title: ""))
        case .edit(let existingBook):
            self._book = State(initialValue: existingBook)
        }
    }

    init(mode: BookFormMode, initialBook: Book, onSave: ((Book) -> Void)? = nil) {
        self.mode = mode
        self.onSave = onSave
        self._book = State(initialValue: initialBook)
    }

    private var isSaveLocked: Bool { isSaving || savedBookAwaitingClose != nil }

    var body: some View {
        NavigationStack {
            BookFormView(
                book: $book,
                imageURL: book.resolvedImageSource,
                mode: mode,
                autoFillButton: {
                    BookAutoFillContainerButton(
                        targetBook: $book,
                        onAutoFillComplete: handleAutoFill
                    )
                },
                onSave: handleSave,
                onCancel: handleCancel,
                onReset: handleReset,
                onCameraTap: handleCameraTap,
                onAdjustPhotoTap: book.localImageFileName == nil ? nil : handleAdjustPhotoTap,
                showsNavigationActions: false
            )
            .disabled(isSaveLocked)
            .navigationTitle(isEditMode ? "図書を編集" : "図書を追加")
            // Keep form navigation actions owned by this screen, outside the Form's
            // autofill sheet and its independently updated row content.
            .toolbar {
                BookFormActions(
                    isEditMode: isEditMode,
                    canSave: !book.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    isEnabled: !isSaveLocked,
                    onSave: handleSave, onCancel: handleCancel
                )
            }
            .interactiveDismissDisabled()
            .onChange(of: book.title) { _, newTitle in
                updateKanaGroup(for: newTitle)
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {
                    if let saved = savedBookAwaitingClose { finishSave(saved) }
                }
            } message: {
                Text(alertState.message)
            }
            .alert("管理番号の確認", isPresented: $isConfirmationPresented) {
                Button("このまま保存", role: .none) {
                    proceedWithSave()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("管理番号が入力されていません。このまま保存しますか？")
            }
            .alert("管理番号が重複しています", isPresented: $isDuplicateConfirmationPresented) {
                Button("このまま保存", role: .destructive) {
                    proceedWithSave()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                if let duplicated = duplicatedBook {
                    Text(
                        "管理番号「\(book.managementNumber ?? "")」は既に図書「\(duplicated.title)」で使用されています。それでも保存しますか？"
                    )
                } else {
                    Text("この管理番号は既に使用されています。それでも保存しますか？")
                }
            }
            #if canImport(UIKit)
                .fullScreenCover(
                    isPresented: $isCameraPresented, onDismiss: { capturedPhoto = nil }
                ) {
                    BookPhotoSheet(
                        photo: $capturedPhoto,
                        adjustingExistingPhoto: $adjustingExistingPhoto,
                        onConfirm: confirmPhoto,
                        onCancel: { isCameraPresented = false })
                }
            #endif
        }
    }

    // MARK: - Computed Properties

    private var isEditMode: Bool {
        if case .edit = mode {
            true
        } else {
            false
        }
    }

    // MARK: - Actions

    private func handleSave() {
        // 管理番号が入力されている場合は重複チェック
        if let managementNumber = book.managementNumber?.trimmingCharacters(
            in: .whitespacesAndNewlines),
            !managementNumber.isEmpty
        {

            // 編集モードの場合は自分自身のIDを除外してチェック
            let excludeId = isEditMode ? book.id : nil

            if let duplicated = bookModel.findBookByManagementNumber(
                managementNumber, excluding: excludeId)
            {
                // 重複している場合は確認モーダルを表示
                duplicatedBook = duplicated
                isDuplicateConfirmationPresented = true
                return
            }
        }

        // 管理番号が未入力または空の場合は確認モーダルを表示
        let hasManagementNumber =
            !(book.managementNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

        if !hasManagementNumber {
            isConfirmationPresented = true
        } else {
            proceedWithSave()
        }
    }

    private func proceedWithSave() {
        guard !isSaveLocked else { return }
        do {
            let savedBook: Book
            switch mode {
            case .add:
                savedBook = try bookModel.registerBook(book)
            case .edit:
                savedBook = try bookModel.updateBook(book)
            }

            let approvedPhoto =
                savedBook.localImageFileName.map { draftImageFiles.contains($0) } ?? false
            isSaving = true
            Task { @MainActor in
                do {
                    if approvedPhoto {
                        try await CoverRecognitionService.shared.approveRegisteredPhoto(savedBook)
                    }
                    isSaving = false
                    finishSave(savedBook)
                } catch {
                    isSaving = false
                    savedBookAwaitingClose = savedBook
                    alertState = .error("図書は保存しました", message: "表紙検索の準備に失敗しました。設定から検索準備を再実行してください。")
                }
            }
        } catch {
            alertState = .error("図書の保存に失敗しました", message: "\(error.localizedDescription)")
        }
    }

    private func finishSave(_ savedBook: Book) {
        cleanDraftImages(keeping: savedBook.localImageFileName)
        onSave?(savedBook)
        Task {
            await CoverRecognitionService.shared.prepare(
                books: bookModel.books, isComplete: bookModel.hasLoadedBooks)
        }
        dismiss()
    }
    private func cleanDraftImages(keeping fileName: String? = nil) {
        for image in draftImageFiles where image != fileName {
            _ = ImageStorageUtility.deleteImage(at: image)
        }
        draftImageFiles = []
    }
    private func handleCancel() {
        cleanDraftImages()
        dismiss()
    }

    private func handleAutoFill(_ filledBook: Book) {
        book = filledBook
        // 自動入力後も五十音分類を更新
        updateKanaGroup(for: book.title)
    }

    /// タイトルに基づいて五十音グループを自動設定
    /// - Parameter title: 図書のタイトル
    private func updateKanaGroup(for title: String) {
        let kanaGroup = KanaGroup.from(text: title)
        book.kanaGroup = kanaGroup
    }

    /// カメラボタンタップ時の処理
    private func handleCameraTap() {
        adjustingExistingPhoto = false
        capturedPhoto = nil
        isCameraPresented = true
    }

    private func handleAdjustPhotoTap() {
        guard let fileName = book.localImageFileName,
            let image = ImageStorageUtility.loadImage(from: fileName)
        else {
            alertState = .error("写真を開けませんでした", message: "写真を撮り直してください。")
            return
        }
        adjustingExistingPhoto = true
        capturedPhoto = image
        isCameraPresented = true
    }

    /// フォームリセット処理
    private func handleReset() {
        cleanDraftImages()
        print("🔄 リセット処理開始")
        // IDを保持したまま他のフィールドをリセット
        let currentId = book.id
        book = Book(id: currentId, title: "")
        print("🔄 リセット完了 - ID: \(currentId)")
        // エラー状態もクリア
        alertState = AlertState()
        // 確認ダイアログの状態もリセット
        isConfirmationPresented = false
        isDuplicateConfirmationPresented = false
        duplicatedBook = nil
    }

    /// 撮影画像の処理
    #if canImport(UIKit)
        private func confirmPhoto(_ image: UIImage) {
            isCameraPresented = false

            do {
                // 画像をローカルに保存（ファイル名のみが返される）
                let fileName = try ImageStorageUtility.saveImage(image)

                // BookのlocalImageFileNameフィールドにファイル名を設定
                book.localImageFileName = fileName
                draftImageFiles.insert(fileName)

            } catch {
                alertState = .error("画像の保存に失敗しました", message: "\(error.localizedDescription)")
            }
        }
    #endif
}

/// Binding-backed content reads the current photo when the sheet first appears.
private struct BookPhotoSheet: View {
    @Binding var photo: UIImage?
    @Binding var adjustingExistingPhoto: Bool
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    var body: some View {
        if let photo {
            CoverPhotoReviewView(
                image: photo,
                onConfirm: onConfirm,
                onRetake: { self.photo = nil },
                onCancel: onCancel,
                adjustingExistingPhoto: adjustingExistingPhoto)
        } else {
            CameraImagePickerView(
                onImagePicked: { photo = $0 },
                onCancel: onCancel,
                cameraDevice: .rear,
                allowsEditing: false)
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(
        repository: mockFactory.bookRepository,
        imageStorageRepository: mockFactory.imageStorageRepository)

    return BookFormContainerView(mode: .add)
        .environment(bookModel)
}
