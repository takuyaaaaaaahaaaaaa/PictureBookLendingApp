import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 設定画面のコンテナビュー
/// 管理者用の絵本・園児・組管理機能を提供します
struct SettingsContainerView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // 組管理
                NavigationView {
                    ClassGroupListContainerView()
                }
                .tabItem {
                    Label("組管理", systemImage: "person.3")
                }
                .tag(0)
                
                // 園児管理
                NavigationView {
                    UserListContainerView()
                }
                .tabItem {
                    Label("園児管理", systemImage: "person.2")
                }
                .tag(1)
                
                // 絵本管理
                NavigationView {
                    BookListContainerView()
                }
                .tabItem {
                    Label("絵本管理", systemImage: "book")
                }
                .tag(2)
            }
            .navigationTitle("設定")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
}

/// 組一覧のコンテナビュー
private struct ClassGroupListContainerView: View {
    @Environment(ClassGroupModel.self) private var classGroupModel
    
    @State private var alertState = AlertState()
    @State private var isAddSheetPresented = false
    
    var body: some View {
        List {
            ForEach(classGroupModel.classGroups) { classGroup in
                ClassGroupRowView(classGroup: classGroup)
            }
            .onDelete(perform: deleteClassGroups)
        }
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
            ClassGroupFormView(onSave: handleAddClassGroup)
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
    
    private func deleteClassGroups(at offsets: IndexSet) {
        for index in offsets {
            let classGroup = classGroupModel.classGroups[index]
            do {
                try classGroupModel.deleteClassGroup(classGroup.id)
            } catch {
                alertState = .error("組の削除に失敗しました")
            }
        }
    }
    
    private func handleAddClassGroup(_ classGroup: ClassGroup) {
        do {
            try classGroupModel.registerClassGroup(classGroup)
            isAddSheetPresented = false
        } catch {
            alertState = .error("組の追加に失敗しました")
        }
    }
}

/// 組一覧の行表示コンポーネント
private struct ClassGroupRowView: View {
    let classGroup: ClassGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(classGroup.name)
                .font(.headline)
            
            Text("\(classGroup.ageGroup)歳児 • \(classGroup.year)年度")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

/// 組追加・編集フォーム
private struct ClassGroupFormView: View {
    let onSave: (ClassGroup) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var ageGroup = 0
    @State private var year = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        NavigationView {
            Form {
                Section("組情報") {
                    TextField("組名", text: $name)
                    
                    Picker("年齢", selection: $ageGroup) {
                        ForEach(0..<6) { age in
                            Text("\(age)歳児").tag(age)
                        }
                    }
                    
                    Picker("年度", selection: $year) {
                        ForEach(2020...2030, id: \.self) { year in
                            Text("\(year)年度").tag(year)
                        }
                    }
                }
            }
            .navigationTitle("組を追加")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let classGroup = ClassGroup(
                            name: name,
                            ageGroup: ageGroup,
                            year: year
                        )
                        onSave(classGroup)
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    SettingsContainerView()
        .environment(ClassGroupModel(repository: MockClassGroupRepository()))
        .environment(UserModel(repository: MockUserRepository()))
        .environment(BookModel(repository: MockBookRepository()))
}
