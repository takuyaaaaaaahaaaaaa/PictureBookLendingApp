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
    @Environment(\.dismiss) private var dismiss
    
    let initialClassGroupId: UUID?
    
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
    /// 登録する保護者の数
    @State private var guardianCount = 1
    /// 保護者登録時に選択する園児
    @State private var selectedChild: User?
    /// 園児の一覧（保護者登録時に使用）
    @State private var availableChildren: [User] = []
    /// 組一覧
    @State private var classGroups: [ClassGroup] = []
    @State private var alertState = AlertState()
    
    init(
        initialClassGroupId: UUID? = nil
    ) {
        self.initialClassGroupId = initialClassGroupId
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
                guardianCount: $guardianCount,
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
                alertState = .error("保護者を登録する場合は関連する園児を選択してください")
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
            _ = try userModel.registerUser(newUser)
            
            // 園児を登録する場合で保護者も一緒に登録するオプションが有効の場合
            if userType == .child && shouldRegisterGuardians {
                for i in 1...guardianCount {
                    let guardianName = i == 1 ? "\(name)の保護者" : "\(name)の保護者(\(i))"
                    let guardian = User(
                        name: guardianName,
                        classGroupId: selectedClassGroup.id,
                        userType: .guardian(relatedChildId: newUser.id)
                    )
                    _ = try userModel.registerUser(guardian)
                }
            }
            
            dismiss()
        } catch {
            alertState = .error("保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    /// 初期読み込み
    private func loadInitialData() {
        // 選択可能な組・園児一覧
        classGroups = classGroupModel.getAllClassGroups()
        availableChildren = userModel.users
            .filter { $0.userType == .child }
        
        // 組が決まっている場合は組固定
        if let initialClassGroupId = initialClassGroupId,
            let initialClassGroup = classGroupModel.findClassGroupById(initialClassGroupId)
        {
            classGroups = [initialClassGroup]
            classGroup = initialClassGroup
            availableChildren = availableChildren.filter {
                $0.classGroupId == initialClassGroupId
            }
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let userModel = UserModel(repository: mockFactory.userRepository)
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    
    return UserFormContainerView()
        .environment(userModel)
        .environment(classGroupModel)
}
