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
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LoanSettingsModel.self) private var loanSettingsModel
    @Environment(\.dismiss) private var dismiss
    
    let initialClassGroupId: UUID?
    var onSave: ((User) -> Void)? = nil
    
    /// 利用者名
    @State private var name = ""
    /// 所属している組
    @State private var classGroup: ClassGroup?
    /// 利用者種別
    @State private var userType: UserType = .child
    /// 利用者種別（ピッカー用）
    @State private var userTypeForPicker: UserTypeForPicker = .child
    /// 保護者も一緒に登録するか
    @State private var shouldRegisterGuardians = true
    /// 保護者登録時に選択する園児
    @State private var selectedChild: User?
    /// 園児の一覧（保護者登録時に使用）
    @State private var availableChildren: [User] = []
    /// 組一覧
    @State private var classGroups: [ClassGroup] = []
    @State private var alertState = AlertState()
    
    init(
        initialClassGroupId: UUID? = nil, onSave: ((User) -> Void)? = nil
    ) {
        self.initialClassGroupId = initialClassGroupId
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            UserFormView(
                editingUser: nil,
                name: $name,
                classGroup: $classGroup,
                classGroups: classGroups,
                userType: $userType,
                userTypeForPicker: $userTypeForPicker,
                shouldRegisterGuardians: $shouldRegisterGuardians,
                guardianCount: loanSettingsModel.settings.guardianCountPerChild,
                availableChildren: availableChildren,
                selectedChild: $selectedChild
            )
            .navigationTitle("利用者を登録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        handleCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") {
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
    
    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && classGroup != nil
    }
    
    // MARK: - Actions
    
    private func handleCancel() {
        dismiss()
    }
    
    private func handleSave() {
        guard let selectedClassGroup = classGroup else {
            alertState = .error("組を選択してください")
            return
        }
        
        // userTypeForPickerからuserTypeを設定
        switch userTypeForPicker {
        case .child:
            userType = .child
        case .guardian:
            // 新規登録で保護者を直接登録する場合は、選択された園児のIDを使用
            guard let selectedChild = selectedChild else {
                alertState = .error("保護者を登録する場合は関連する利用者を選択してください")
                return
            }
            userType = .guardian(relatedChildId: selectedChild.id)
        }
        
        do {
            // 新規登録
            let newUser = User(
                name: name,
                classGroupId: selectedClassGroup.id,
                userType: userType
            )
            let savedUser = try userModel.registerUser(newUser)
            
            // 園児を登録する場合で保護者も一緒に登録するオプションが有効の場合
            if userType == .child && shouldRegisterGuardians {
                let guardianCount = loanSettingsModel.settings.guardianCountPerChild
                for i in 1...guardianCount {
                    let guardianName = "\(name)の保護者\(i)"
                    let guardian = User(
                        name: guardianName,
                        classGroupId: selectedClassGroup.id,
                        userType: .guardian(relatedChildId: newUser.id)
                    )
                    _ = try userModel.registerUser(guardian)
                }
            }
            
            onSave?(savedUser)
            dismiss()
        } catch {
            alertState = .error("保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func loadInitialData() {
        classGroups = classGroupModel.getAllClassGroups()
        
        // 園児一覧を取得（保護者登録時に使用）
        availableChildren = userModel.users.filter { user in
            if case .child = user.userType {
                return true
            }
            return false
        }
        
        // 新規登録時のデフォルト値設定
        shouldRegisterGuardians = loanSettingsModel.settings.defaultRegisterGuardians
        if let initialClassGroupId = initialClassGroupId {
            classGroup = classGroupModel.findClassGroupById(initialClassGroupId)
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let userModel = UserModel(repository: mockFactory.userRepository)
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    let loanSettingsModel = LoanSettingsModel(repository: mockFactory.loanSettingsRepository)
    
    return UserFormContainerView()
        .environment(userModel)
        .environment(classGroupModel)
        .environment(loanSettingsModel)
}
