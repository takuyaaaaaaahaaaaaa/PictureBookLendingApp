import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 組一覧のContainer View
///
/// ビジネスロジック、状態管理、データ取得を担当し、
/// Presentation ViewにデータとアクションHookを提供します。
struct ClassGroupListContainerView: View {
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    @State private var alertState = AlertState()
    @State private var isAddSheetPresented = false
    @State private var editingClassGroup: ClassGroup?
    
    var body: some View {
        ClassGroupListView(
            classGroups: classGroupModel.classGroups,
            onAdd: handleAdd,
            onEdit: handleEdit,
            onDelete: handleDelete
        )
        .navigationTitle("組管理")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("追加") {
                    isAddSheetPresented = true
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
    
    private func handleEdit(_ classGroup: ClassGroup) {
        editingClassGroup = classGroup
    }
    
    private func handleDelete(at offsets: IndexSet) {
        for index in offsets {
            let classGroup = classGroupModel.classGroups[index]
            do {
                try classGroupModel.deleteClassGroup(classGroup.id)
            } catch {
                alertState = .error("組の削除に失敗しました")
            }
        }
    }
    
    private func handleSave(_ classGroup: ClassGroup) {
        do {
            try classGroupModel.registerClassGroup(classGroup)
            isAddSheetPresented = false
        } catch {
            alertState = .error("組の追加に失敗しました")
        }
    }
    
    private func handleUpdate(_ classGroup: ClassGroup) {
        do {
            try classGroupModel.updateClassGroup(classGroup)
            editingClassGroup = nil
        } catch {
            alertState = .error("組の更新に失敗しました")
        }
    }
}

#Preview {
    NavigationStack {
        ClassGroupListContainerView()
            .environment(ClassGroupModel(repository: MockClassGroupRepository()))
    }
}
