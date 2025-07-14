import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 利用者フォームのContainer View
///
/// ビジネスロジック、状態管理、データ保存を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct UserFormContainerView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.dismiss) private var dismiss
    
    let mode: UserFormMode
    var onSave: ((User) -> Void)? = nil
    
    @State private var name = ""
    @State private var group = ""
    @State private var alertState = AlertState()
    
    init(mode: UserFormMode, onSave: ((User) -> Void)? = nil) {
        self.mode = mode
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            UserFormView(
                mode: mode,
                name: $name,
                group: $group,
                isValidInput: isValidInput,
                onSave: handleSave,
                onCancel: handleCancel
            )
            .navigationTitle(isEditMode ? "利用者情報を編集" : "利用者を登録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        handleCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "保存" : "登録") {
                        handleSave()
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
                loadInitialData()
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
    
    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !group.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    
    private func handleCancel() {
        dismiss()
    }
    
    private func handleSave() {
        do {
            let savedUser: User
            
            switch mode {
            case .add:
                let newUser = User(name: name, group: group)
                savedUser = try userModel.registerUser(newUser)

            case .edit(let user):
                let updatedUser = User(
                    id: user.id,
                    name: name,
                    group: group
                )
                savedUser = try userModel.updateUser(updatedUser)
            }
            
            onSave?(savedUser)
            dismiss()
        } catch {
            alertState = .error("保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func loadInitialData() {
        if case .edit(let user) = mode {
            name = user.name
            group = user.group
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let userModel = UserModel(repository: mockFactory.userRepository)
    
    return UserFormContainerView(mode: .add)
        .environment(userModel)
}
