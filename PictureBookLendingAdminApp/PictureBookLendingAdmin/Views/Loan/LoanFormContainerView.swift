import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出フォームのContainer View
///
/// ビジネスロジック、状態管理、データ取得を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct LoanFormContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(LoanModel.self) private var loanModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(\.dismiss) private var dismiss
    
    let preselectedBookId: UUID?
    
    @State private var selectedClassGroup: ClassGroup?
    @State private var selectedUserId: UUID?
    @State private var dueDate =
        Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var alertState = AlertState()
    
    var body: some View {
        NavigationStack {
            LoanFormView(
                book: selectedBook,
                classGroups: classGroupModel.getAllClassGroups(),
                users: filteredUsersForSelectedClassGroup,
                selectedClassGroup: $selectedClassGroup,
                selectedUserId: selectedUserId,
                dueDate: dueDate,
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
    
    private var selectedBook: Book {
        guard let preselectedBookId = preselectedBookId,
            let book = bookModel.findBookById(preselectedBookId)
        else {
            // デフォルトとして最初の絵本を返す（実際の使用では事前選択が前提）
            return bookModel.getAllBooks().first ?? Book(title: "絵本が選択されていません", author: "")
        }
        return book
    }
    
    private var filteredUsersForSelectedClassGroup: [User] {
        guard let selectedClassGroup = selectedClassGroup else {
            return []
        }
        
        return userModel.getAllUsers().filter { user in
            user.classGroupId == selectedClassGroup.id
        }
    }
    
    private var isValidInput: Bool {
        preselectedBookId != nil && selectedUserId != nil && dueDate > Date()
    }
    
    // MARK: - Actions
    
    private func handleUserSelect(_ userId: UUID) {
        selectedUserId = userId
    }
    
    private func handleCancel() {
        dismiss()
    }
    
    private func handleRegister() {
        guard let bookId = preselectedBookId,
            let userId = selectedUserId
        else {
            alertState = .error("必要な情報が選択されていません")
            return
        }
        
        do {
            // 最新データで状態を更新してから貸出処理
            loanModel.refreshLoans()
            
            // すでに貸出中かどうか再確認
            if loanModel.isBookLent(bookId: bookId) {
                alertState = .error("この絵本はすでに貸出中です")
                return
            }
            
            _ = try loanModel.lendBook(bookId: bookId, userId: userId, dueDate: dueDate)
            dismiss()
        } catch LoanModelError.bookAlreadyLent {
            alertState = .error("この絵本はすでに貸出中です")
        } catch LoanModelError.bookNotFound {
            alertState = .error("選択された絵本が見つかりません")
        } catch LoanModelError.userNotFound {
            alertState = .error("選択された利用者が見つかりません")
        } catch {
            alertState = .error("貸出登録に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func refreshData() {
        bookModel.refreshBooks()
        userModel.refreshUsers()
        loanModel.refreshLoans()
        classGroupModel.refreshClassGroups()
    }
}

#Preview {
    let mockRepositoryFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockRepositoryFactory.bookRepository)
    let userModel = UserModel(repository: mockRepositoryFactory.userRepository)
    let loanModel = LoanModel(
        repository: mockRepositoryFactory.loanRepository,
        bookRepository: mockRepositoryFactory.bookRepository,
        userRepository: mockRepositoryFactory.userRepository,
        loanSettingsRepository: mockRepositoryFactory.loanSettingsRepository
    )
    let classGroupModel = ClassGroupModel(repository: mockRepositoryFactory.classGroupRepository)
    
    LoanFormContainerView(preselectedBookId: nil)
        .environment(bookModel)
        .environment(userModel)
        .environment(loanModel)
        .environment(classGroupModel)
}
