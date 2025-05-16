import SwiftUI
import PictureBookLendingCore

/**
 * 新規貸出登録ビュー
 *
 * 絵本の新規貸出を登録するためのフォームを提供します。
 */
struct NewLoanView: View {
    @Environment(\.bookModel) private var bookModel
    @Environment(\.userModel) private var userModel
    @Environment(\.lendingModel) private var lendingModel
    @Environment(\.dismiss) private var dismiss
    
    // 選択された絵本のID
    @State private var selectedBookId: UUID?
    
    // 選択された利用者のID
    @State private var selectedUserId: UUID?
    
    // 返却期限
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    
    // エラー表示用
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // 書籍検索
    @State private var bookSearchText = ""
    
    // 利用者検索
    @State private var userSearchText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("絵本を選択")) {
                    if let bookModel = bookModel, let books = filteredBooks(bookModel) {
                        if books.isEmpty {
                            Text("検索条件に一致する絵本はありません")
                                .italic()
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(books) { book in
                                BookSelectionRow(
                                    book: book,
                                    isSelected: book.id == selectedBookId,
                                    isLent: isBookLent(book.id)
                                ) {
                                    selectedBookId = book.id
                                }
                                .disabled(isBookLent(book.id))
                            }
                        }
                    } else {
                        Text("絵本情報を読み込めませんでした")
                            .foregroundColor(.red)
                    }
                }
                .searchable(text: $bookSearchText, prompt: "絵本を検索")
                
                Section(header: Text("利用者を選択")) {
                    if let userModel = userModel, let users = filteredUsers(userModel) {
                        if users.isEmpty {
                            Text("検索条件に一致する利用者はいません")
                                .italic()
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(users) { user in
                                UserSelectionRow(
                                    user: user,
                                    isSelected: user.id == selectedUserId
                                ) {
                                    selectedUserId = user.id
                                }
                            }
                        }
                    } else {
                        Text("利用者情報を読み込めませんでした")
                            .foregroundColor(.red)
                    }
                }
                .searchable(text: $userSearchText, prompt: "利用者を検索")
                
                Section(header: Text("返却期限")) {
                    DatePicker(
                        "返却期限",
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
            }
            .navigationTitle("貸出登録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
                        registerLoan()
                    }
                    .disabled(!isValidInput)
                }
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // 入力値が有効かどうか
    private var isValidInput: Bool {
        selectedBookId != nil && selectedUserId != nil && dueDate > Date()
    }
    
    // フィルタリングされた書籍リスト
    private func filteredBooks(_ bookModel: BookModel) -> [Book]? {
        let books = bookModel.getAllBooks()
        
        if bookSearchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.title.localizedCaseInsensitiveContains(bookSearchText) ||
                book.author.localizedCaseInsensitiveContains(bookSearchText)
            }
        }
    }
    
    // フィルタリングされた利用者リスト
    private func filteredUsers(_ userModel: UserModel) -> [User]? {
        let users = userModel.getAllUsers()
        
        if userSearchText.isEmpty {
            return users
        } else {
            return users.filter { user in
                user.name.localizedCaseInsensitiveContains(userSearchText) ||
                user.group.localizedCaseInsensitiveContains(userSearchText)
            }
        }
    }
    
    // 書籍が貸出中かどうかのチェック
    private func isBookLent(_ bookId: UUID) -> Bool {
        guard let lendingModel = lendingModel else { return false }
        return lendingModel.isBookLent(bookId: bookId)
    }
    
    // 貸出登録
    private func registerLoan() {
        guard let lendingModel = lendingModel,
              let bookId = selectedBookId,
              let userId = selectedUserId else {
            showError("必要な情報が選択されていません")
            return
        }
        
        do {
            _ = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
            dismiss()
        } catch {
            showError("貸出登録に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // エラー表示
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

/**
 * 絵本選択行ビュー
 */
struct BookSelectionRow: View {
    let book: Book
    let isSelected: Bool
    let isLent: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(isLent ? .secondary : .primary)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isLent {
                Text("貸出中")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.2))
                    )
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isLent {
                onTap()
            }
        }
        .padding(.vertical, 4)
    }
}

/**
 * 利用者選択行ビュー
 */
struct UserSelectionRow: View {
    let user: User
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                
                Text(user.group)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NewLoanView()
}