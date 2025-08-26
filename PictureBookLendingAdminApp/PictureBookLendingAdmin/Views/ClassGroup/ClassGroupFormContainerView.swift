//
//  ClassGroupFormContainerView.swift
//  PictureBookLendingAdmin
//
//  Created by takuya_tominaga on 7/19/25.
//
import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 組フォームのContainer View
///
/// 組の追加・編集フォームの状態管理とビジネスロジックを担当します。
struct ClassGroupFormContainerView: View {
    let mode: ClassGroupFormMode
    let onSave: (ClassGroup) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var ageGroup = AgeGroup.age(0)
    @State private var year = Calendar.current.component(.year, from: Date())
    
    init(mode: ClassGroupFormMode, onSave: @escaping (ClassGroup) -> Void) {
        self.mode = mode
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ClassGroupFormView(
                mode: mode,
                name: $name,
                ageGroup: $ageGroup,
                year: $year
            )
            .navigationTitle(mode.title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        handleCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        handleSave()
                    }
                    .disabled(!isValidInput)
                }
            }
            .onAppear {
                loadInitialData()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidInput: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    
    private func handleSave() {
        switch mode {
        case .add:
            let classGroup = ClassGroup(
                name: name,
                ageGroup: ageGroup,
                year: year
            )
            onSave(classGroup)
        case .edit(let classGroup):
            let updateClassGroup = ClassGroup(
                id: classGroup.id,
                name: name,
                ageGroup: ageGroup,
                year: year
            )
            onSave(updateClassGroup)
        }
    }
    
    private func handleCancel() {
        dismiss()
    }
    
    private func loadInitialData() {
        if case .edit(let classGroup) = mode {
            name = classGroup.name
            ageGroup = classGroup.ageGroup
            year = classGroup.year
        }
    }
}
