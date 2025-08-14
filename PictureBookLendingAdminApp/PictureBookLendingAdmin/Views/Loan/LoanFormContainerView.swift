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
    @Environment(LoanSettingsModel.self) private var loanSettingModel
    @Environment(\.dismiss) private var dismiss
    
    /// 選択した絵本
    let selectedBook: Book
    /// 選択したクラス（組）
    @State private var selectedClassGroup: ClassGroup?
    /// 選択した利用者
    @State private var selectedUser: User?
    @State private var alertState = AlertState()
    
    var body: some View {
        NavigationStack {
            LoanFormView(
                book: selectedBook,
                classGroups: classGroupModel.getAllClassGroups(),
                users: filteredUsersForSelectedClassGroup,
                dueDate: dueDate,
                selectedClassGroup: $selectedClassGroup,
                selectedUser: $selectedUser,
                isValidInput: isValidInput
            )
            // 選択中の組が変化した場合、選択中の利用者情報を初期化
            .onChange(of: selectedClassGroup) { _, _ in
                selectedUser = nil
            }
            .navigationTitle("貸出登録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        handleCancel()
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button("登録") {
                        handleRegister()
                    }
                    .disabled(!isValidInput)
                }
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                if alertState.type == .success {
                    Button("OK", role: .cancel) {
                        dismiss()  // 成功時は画面を閉じる
                    }
                } else {
                    Button("OK", role: .cancel) {}
                }
            } message: {
                Text(alertState.message)
            }
            .onAppear {
                refreshData()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// 返却予定日
    private var dueDate: Date {
        loanSettingModel.settings.calculateDueDate(from: Date())
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
        selectedUser != nil
    }
    
    // MARK: - Actions
    
    private func handleCancel() {
        dismiss()
    }
    
    private func handleRegister() {
        guard let user = selectedUser else {
            alertState = .error("必要な情報が選択されていません")
            return
        }
        
        do {
            // 最新データで状態を更新してから貸出処理
            loanModel.refreshLoans()
            
            // すでに貸出中かどうか再確認
            if loanModel.isBookLent(bookId: selectedBook.id) {
                alertState = .error("この絵本はすでに貸出中です")
                return
            }
            
            _ = try loanModel.lendBook(bookId: selectedBook.id, userId: user.id)
            alertState = .success("貸出登録が完了しました")
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
        userModel.refreshUsers()
        loanModel.refreshLoans()
        classGroupModel.refreshClassGroups()
    }
}

#Preview {
    let mockRepositoryFactory = MockRepositoryFactory()
    let userModel = UserModel(repository: mockRepositoryFactory.userRepository)
    let loanModel = LoanModel(
        repository: mockRepositoryFactory.loanRepository,
        bookRepository: mockRepositoryFactory.bookRepository,
        userRepository: mockRepositoryFactory.userRepository,
        loanSettingsRepository: mockRepositoryFactory.loanSettingsRepository
    )
    let classGroupModel = ClassGroupModel(repository: mockRepositoryFactory.classGroupRepository)
    let loanSettingModel = LoanSettingsModel(
        repository: mockRepositoryFactory.loanSettingsRepository)
    
    let selectedBook = Book(title: "りんごかもしれない", author: "ヨシタケ・シンスケ")
    
    LoanFormContainerView(selectedBook: selectedBook)
        .environment(userModel)
        .environment(loanModel)
        .environment(classGroupModel)
        .environment(loanSettingModel)
}
