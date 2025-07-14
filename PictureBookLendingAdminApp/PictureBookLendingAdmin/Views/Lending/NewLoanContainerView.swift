import SwiftUI
import PictureBookLendingDomain
import PictureBookLendingModel
import PictureBookLendingUI
import PictureBookLendingInfrastructure

/**
 * 新規貸出登録のContainer View
 *
 * ビジネスロジック、状態管理、データ取得を担当し、
 * Presentation ViewにデータとアクションHookを提供します。
 */
struct NewLoanContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(LendingModel.self) private var lendingModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedBookId: UUID?
    @State private var selectedUserId: UUID?
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var bookSearchText = ""
    @State private var userSearchText = ""
    @State private var alertState = AlertState()
    
    var body: some View {
        NavigationStack {
            NewLoanView(
                books: filteredBooks,
                users: filteredUsers,
                selectedBookId: selectedBookId,
                selectedUserId: selectedUserId,
                dueDate: dueDate,
                bookSearchText: $bookSearchText,
                userSearchText: $userSearchText,
                dueDateBinding: $dueDate,
                isBookLent: { bookModel in lendingModel.isBookLent(bookId: bookModel) },
                onBookSelect: handleBookSelect,
                onUserSelect: handleUserSelect,
                onCancel: handleCancel,
                onRegister: handleRegister,
                isValidInput: isValidInput
            )
            .navigationTitle("貸出登録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        handleCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
                        handleRegister()
                    }
                    .disabled(!isValidInput)
                }
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertState.message)
            }
            .onAppear {
                refreshData()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredBooks: [Book] {
        let books = bookModel.getAllBooks()
        
        return if bookSearchText.isEmpty {
            books
        } else {
            books.filter { book in
                book.title.localizedCaseInsensitiveContains(bookSearchText) ||
                book.author.localizedCaseInsensitiveContains(bookSearchText)
            }
        }
    }
    
    private var filteredUsers: [User] {
        let users = userModel.getAllUsers()
        
        return if userSearchText.isEmpty {
            users
        } else {
            users.filter { user in
                user.name.localizedCaseInsensitiveContains(userSearchText) ||
                user.group.localizedCaseInsensitiveContains(userSearchText)
            }
        }
    }
    
    private var isValidInput: Bool {
        selectedBookId != nil && selectedUserId != nil && dueDate > Date()
    }
    
    // MARK: - Actions
    
    private func handleBookSelect(_ bookId: UUID) {
        selectedBookId = bookId
    }
    
    private func handleUserSelect(_ userId: UUID) {
        selectedUserId = userId
    }
    
    private func handleCancel() {
        dismiss()
    }
    
    private func handleRegister() {
        guard let bookId = selectedBookId,
              let userId = selectedUserId else {
            alertState = .error("必要な情報が選択されていません")
            return
        }
        
        do {
            // 最新データで状態を更新してから貸出処理
            lendingModel.refreshLoans()
            
            // すでに貸出中かどうか再確認
            if lendingModel.isBookLent(bookId: bookId) {
                alertState = .error("この絵本はすでに貸出中です")
                return
            }
            
            _ = try lendingModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
            dismiss()
        } catch LendingModelError.bookAlreadyLent {
            alertState = .error("この絵本はすでに貸出中です")
        } catch LendingModelError.bookNotFound {
            alertState = .error("選択された絵本が見つかりません")
        } catch LendingModelError.userNotFound {
            alertState = .error("選択された利用者が見つかりません")
        } catch {
            alertState = .error("貸出登録に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func refreshData() {
        bookModel.refreshBooks()
        userModel.refreshUsers()
        lendingModel.refreshLoans()
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    return NewLoanContainerView()
        .environment(bookModel)
        .environment(userModel)
        .environment(lendingModel)
}