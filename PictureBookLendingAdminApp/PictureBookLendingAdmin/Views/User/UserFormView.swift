import SwiftUI
import PictureBookLendingInfrastructure
import PictureBookLendingDomain
import Observation

/// 利用者フォームの操作モード
enum UserFormMode {
    case add
    case edit(User)
}

/**
 * 利用者情報入力フォームビュー
 *
 * 利用者の新規登録と既存利用者の編集に使用できるフォームビューです。
 */
struct UserFormView: View {
    let userModel: UserModel
    
    // フォームのモード（追加/編集）
    let mode: UserFormMode
    
    // 保存完了時のコールバック
    var onSave: ((User) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    // フォーム入力値
    @State private var name: String = ""
    @State private var group: String = ""
    
    // エラー表示用
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("利用者情報")) {
                    TextField("名前", text: $name)
                    TextField("グループ（クラスなど）", text: $group)
                }
            }
            .navigationTitle(isEditMode ? "利用者情報を編集" : "利用者を登録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "保存" : "登録") {
                        saveUser()
                    }
                    .disabled(!isValidInput)
                }
            }
            .onAppear {
                // 編集モードの場合、初期値をセット
                if case .edit(let user) = mode {
                    name = user.name
                    group = user.group
                }
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // 編集モードかどうか
    private var isEditMode: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }
    
    // 入力値が有効かどうか
    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !group.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // 利用者の保存/更新処理
    private func saveUser() {
        do {
            switch mode {
            case .add:
                let newUser = User(name: name, group: group)
                let savedUser = try userModel.registerUser(newUser)
                onSave?(savedUser)
                
            case .edit(let user):
                let updatedUser = User(
                    id: user.id,
                    name: name,
                    group: group
                )
                let savedUser = try userModel.updateUser(updatedUser)
                onSave?(savedUser)
            }
            
            dismiss()
        } catch {
            showError("保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // エラー表示
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let userModel = UserModel(repository: mockFactory.userRepository)
    return UserFormView(userModel: userModel, mode: .add)
}