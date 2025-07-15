import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 組管理のコンテナビュー
///
/// 組の一覧表示、新規登録、編集、削除機能を提供します。
struct GroupManagementContainerView: View {
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(UserModel.self) private var userModel
    
    @State private var searchText = ""
    @State private var isAddSheetPresented = false
    @State private var alertState = AlertState()
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 検索・追加ヘッダー
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("組名で検索", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    if !searchText.isEmpty {
                        Button("クリア") {
                            searchText = ""
                        }
                        .foregroundStyle(.blue)
                    }
                }
                
                Button("新規追加") {
                    isAddSheetPresented = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // 組一覧
            if isLoading {
                LoadingView(message: "組情報を読み込み中...")
            } else if filteredGroups.isEmpty {
                EmptyStateView(
                    title: searchText.isEmpty ? "組が登録されていません" : "該当する組が見つかりません",
                    message: searchText.isEmpty ? 
                        "「新規追加」ボタンから最初の組を登録してください。" :
                        "「\(searchText)」に一致する組が見つかりません。",
                    systemImage: "person.3.fill"
                )
            } else {
                List {
                    ForEach(filteredGroups) { group in
                        GroupRowView(
                            group: group,
                            userCount: userCount(for: group)
                        )
                    }
                    .onDelete(perform: deleteGroups)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("組管理")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
        .sheet(isPresented: $isAddSheetPresented) {
            GroupFormContainerView(group: nil)
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private var filteredGroups: [ClassGroup] {
        if searchText.isEmpty {
            return classGroupModel.classGroups
        } else {
            return classGroupModel.classGroups.filter { group in
                group.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func userCount(for group: ClassGroup) -> Int {
        userModel.users.filter { $0.classGroupId == group.id }.count
    }
    
    private func deleteGroups(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let group = filteredGroups[index]
                let usersInGroup = userCount(for: group)
                
                if usersInGroup > 0 {
                    alertState = AlertState(
                        title: "削除できません",
                        message: "「\(group.name)」には\(usersInGroup)人の園児が所属しているため削除できません。先に園児を移動させてください。"
                    )
                    return
                }
                
                do {
                    try await classGroupModel.delete(group.id)
                } catch {
                    alertState = AlertState(
                        title: "削除エラー",
                        message: "組の削除に失敗しました: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await classGroupModel.load()
            try await userModel.load()
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "データの読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 組行ビュー
private struct GroupRowView: View {
    let group: ClassGroup
    let userCount: Int
    
    @State private var isEditSheetPresented = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                
                Text("\(userCount)人の園児")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("編集") {
                isEditSheetPresented = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .sheet(isPresented: $isEditSheetPresented) {
            GroupFormContainerView(group: group)
        }
    }
}

/// 組フォームのコンテナビュー（簡易版）
private struct GroupFormContainerView: View {
    let group: ClassGroup?
    
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var alertState = AlertState()
    @State private var isProcessing = false
    
    private var isEditing: Bool { group != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("組情報") {
                    TextField("組名", text: $name)
                }
            }
            .navigationTitle(isEditing ? "組編集" : "組追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "更新" : "追加") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(name.isEmpty || isProcessing)
                }
            }
            .onAppear {
                if let group = group {
                    name = group.name
                }
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertState.message)
            }
        }
    }
    
    private func save() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            if let group = group {
                let updatedGroup = ClassGroup(
                    id: group.id,
                    name: name,
                    userCount: group.userCount
                )
                try await classGroupModel.update(updatedGroup)
            } else {
                let newGroup = ClassGroup(
                    id: UUID(),
                    name: name,
                    userCount: 0
                )
                try await classGroupModel.add(newGroup)
            }
            dismiss()
        } catch {
            alertState = AlertState(
                title: "保存エラー",
                message: "組の保存に失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 空状態表示用ビュー
private struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    
    NavigationStack {
        GroupManagementContainerView()
            .environment(classGroupModel)
            .environment(userModel)
    }
}