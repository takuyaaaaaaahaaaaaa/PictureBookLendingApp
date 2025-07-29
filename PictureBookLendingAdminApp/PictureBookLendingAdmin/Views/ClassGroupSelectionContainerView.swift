import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 組選択画面のコンテナビュー
struct ClassGroupSelectionContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    let onSelect: (ClassGroup) -> Void
    
    @State private var alertState = AlertState()
    
    var body: some View {
        ClassGroupSelectionView(
            classGroups: classGroupModel.classGroups,
            onSelect: handleSelect
        )
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
        .onAppear {
            refreshClassGroups()
        }
    }
    
    private func handleSelect(_ classGroup: ClassGroup) {
        onSelect(classGroup)
        dismiss()
    }
    
    private func refreshClassGroups() {
        classGroupModel.refreshClassGroups()
    }
}

#Preview {
    ClassGroupSelectionContainerView { _ in }
        .environment(ClassGroupModel(repository: MockClassGroupRepository()))
}
