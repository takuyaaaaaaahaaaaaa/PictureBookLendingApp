import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 組一覧のContainer View
///
/// ビジネスロジック、状態管理、データ取得を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
/// 利用者管理の組選択画面としても使用されます。
struct ClassGroupListContainerView: View {
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(UserModel.self) private var userModel
    
    @State private var alertState = AlertState()
    @State private var isAddSheetPresented = false
    @State private var editingClassGroup: ClassGroup?
    @State private var isEditMode = false
    
    let onClassGroupSelected: ((UUID) -> Void)?
    
    init(onClassGroupSelected: ((UUID) -> Void)? = nil) {
        self.onClassGroupSelected = onClassGroupSelected
    }
    
    var body: some View {
        ClassGroupListView(
            classGroups: classGroupModel.classGroups,
            getChildCount: getChildCountForClassGroup,
            getGuardianCount: getGuardianCountForClassGroup,
            isEditMode: isEditMode,
            onAdd: handleAdd,
            onSelect: handleSelectClassGroup,
            onEdit: handleEditClassGroup,
            onDelete: handleDelete
        )
        .navigationTitle("組一覧")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(id: "fix") {
                Button(isEditMode ? "編集モード終了" : "組編集モード") {
                    isEditMode.toggle()
                }
            }
            
            ToolbarSpacer(.fixed)
            
            ToolbarItem(id: "add") {
                Button {
                    handleAdd()
                } label: {
                    Label("組を追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddSheetPresented) {
            ClassGroupFormContainerView(
                mode: .add,
                onSave: handleSave
            )
        }
        .sheet(item: $editingClassGroup) { classGroup in
            ClassGroupFormContainerView(
                mode: .edit(classGroup),
                onSave: handleUpdate
            )
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .onAppear {
            classGroupModel.refreshClassGroups()
        }
    }
    
    // MARK: - Actions
    
    private func handleAdd() {
        isAddSheetPresented = true
    }
    
    private func handleSelectClassGroup(_ classGroup: ClassGroup) {
        onClassGroupSelected?(classGroup.id)
    }
    
    private func handleEditClassGroup(_ classGroup: ClassGroup) {
        editingClassGroup = classGroup
    }
    
    private func getChildCountForClassGroup(_ classGroupId: UUID) -> Int {
        userModel.users.filter { user in
            user.classGroupId == classGroupId && user.userType == .child
        }.count
    }
    
    private func getGuardianCountForClassGroup(_ classGroupId: UUID) -> Int {
        userModel.users.filter { user in
            user.classGroupId == classGroupId
                && {
                    if case .guardian = user.userType {
                        return true
                    }
                    return false
                }()
        }.count
    }
    
    private func handleDelete(at offsets: IndexSet) {
        for index in offsets {
            let classGroup = classGroupModel.classGroups[index]
            do {
                try classGroupModel.deleteClassGroup(classGroup.id)
            } catch {
                alertState = .error("組の削除に失敗しました", message: error.localizedDescription)
            }
        }
    }
    
    private func handleSave(_ classGroup: ClassGroup) {
        do {
            try classGroupModel.registerClassGroup(classGroup)
            isAddSheetPresented = false
        } catch {
            alertState = .error("組の追加に失敗しました", message: error.localizedDescription)
        }
    }
    
    private func handleUpdate(_ classGroup: ClassGroup) {
        do {
            try classGroupModel.updateClassGroup(classGroup)
            editingClassGroup = nil
        } catch {
            alertState = .error("組の更新に失敗しました", message: error.localizedDescription)
        }
    }
}

#Preview {
    NavigationStack {
        ClassGroupListContainerView()
            .environment(ClassGroupModel(repository: MockClassGroupRepository()))
    }
}
