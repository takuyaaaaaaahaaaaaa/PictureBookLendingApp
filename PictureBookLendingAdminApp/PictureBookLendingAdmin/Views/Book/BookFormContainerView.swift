import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

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
    
    var body: some View {
        NavigationStack {
            BookFormView(
                book: $book,
                mode: mode,
                autoFillButton: {
                    BookAutoFillContainerButton(
                        targetBook: $book,
                        onAutoFillComplete: handleAutoFill
                    )
                },
                onSave: handleSave,
                onCancel: handleCancel,
                onCameraTap: handleCameraTap
            )
            .navigationTitle(isEditMode ? "絵本を編集" : "絵本を追加")
            .interactiveDismissDisabled()
            .onChange(of: book.title) { _, newTitle in
                updateKanaGroup(for: newTitle)
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
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
                        "管理番号「\(book.managementNumber ?? "")」は既に絵本「\(duplicated.title)」で使用されています。それでも保存しますか？"
                    )
                } else {
                    Text("この管理番号は既に使用されています。それでも保存しますか？")
                }
            }
            .sheet(isPresented: $isCameraPresented) {
                CameraImagePickerView(
                    onImagePicked: handleImagePicked,
                    onCancel: {
                        isCameraPresented = false
                    }
                )
            }
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
            book.managementNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        
        if !hasManagementNumber {
            isConfirmationPresented = true
        } else {
            proceedWithSave()
        }
    }
    
    private func proceedWithSave() {
        do {
            let savedBook: Book
            switch mode {
            case .add:
                savedBook = try bookModel.registerBook(book)
            case .edit:
                savedBook = try bookModel.updateBook(book)
            }
            
            onSave?(savedBook)
            dismiss()
        } catch {
            alertState = .error("保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func handleCancel() {
        dismiss()
    }
    
    private func handleAutoFill(_ filledBook: Book) {
        book = filledBook
        // 自動入力後も五十音分類を更新
        updateKanaGroup(for: book.title)
    }
    
    /// タイトルに基づいて五十音グループを自動設定
    /// - Parameter title: 絵本のタイトル
    private func updateKanaGroup(for title: String) {
        let kanaGroup = KanaGroup.from(text: title)
        book.kanaGroup = kanaGroup
    }
    
    /// カメラボタンタップ時の処理
    private func handleCameraTap() {
        isCameraPresented = true
    }
    
    /// 撮影画像の処理
    private func handleImagePicked(_ image: UIImage) {
        isCameraPresented = false
        
        do {
            // 画像をローカルに保存
            let localPath = try ImageStorageUtility.saveImage(image)
            
            // Bookのthumbnailフィールドにローカルパスを設定
            book.thumbnail = localPath
            
        } catch {
            alertState = .error("画像の保存に失敗しました: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    
    return BookFormContainerView(mode: .add)
        .environment(bookModel)
}
