import PictureBookLendingDomain
import SwiftUI

/// 利用者一覧のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct UserListView<RowContent: View>: View {
    let users: [User]
    let searchText: Binding<String>
    let showChildren: Binding<Bool>
    let showGuardians: Binding<Bool>
    let onDelete: (IndexSet) -> Void
    let rowContent: (User) -> RowContent
    
    public init(
        users: [User],
        searchText: Binding<String>,
        showChildren: Binding<Bool> = .constant(true),
        showGuardians: Binding<Bool> = .constant(true),
        onDelete: @escaping (IndexSet) -> Void,
        @ViewBuilder rowContent: @escaping (User) -> RowContent
    ) {
        self.users = users
        self.searchText = searchText
        self.showChildren = showChildren
        self.showGuardians = showGuardians
        self.onDelete = onDelete
        self.rowContent = rowContent
    }
    
    public var body: some View {
        List {
            // リストの最初にフィルターセクションを追加
            Section {
                userFilterView
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // ユーザーリスト
            if users.isEmpty {
                Section {
                    ContentUnavailableView(
                        "利用者がいません",
                        systemImage: "person.slash",
                        description: Text("右上の＋ボタンから利用者を登録してください")
                    )
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(users) { user in
                        NavigationLink(value: user) {
                            rowContent(user)
                        }
                    }
                    .onDelete(perform: onDelete)
                }
            }
        }
        #if os(iOS)
            .searchable(
                text: searchText, placement: .navigationBarDrawer(displayMode: .always),
                prompt: "名前またはグループで検索")
        #else
            .searchable(text: searchText, prompt: "名前またはグループで検索")
        #endif
        
    }
    
    var userFilterView: some View {
        HStack(spacing: 16) {
            Toggle("本人", isOn: showChildren)
                .toggleStyle(.button)
            
            Toggle("保護者", isOn: showGuardians)
                .toggleStyle(.button)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.regularMaterial)
    }
}

/// 利用者リスト行ビュー
///
/// 一覧の各行に表示する利用者情報のレイアウトを定義します。
public struct UserRowView: View {
    let user: User
    let classGroupName: String
    
    public init(user: User, classGroupName: String) {
        self.user = user
        self.classGroupName = classGroupName
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(user.name)
                    .font(.headline)
                
                Spacer()
                
                Text(user.userType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(userTypeBadgeColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            
            Text(classGroupName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var userTypeBadgeColor: Color {
        switch user.userType {
        case .child:
            return .blue
        case .guardian:
            return .green
        }
    }
}

#Preview {
    let user1 = User(name: "山田太郎", classGroupId: UUID())
    let user2 = User(name: "鈴木花子", classGroupId: UUID())
    
    NavigationStack {
        UserListView(
            users: [user1, user2],
            searchText: .constant(""),
            showChildren: .constant(true),
            showGuardians: .constant(true),
            onDelete: { _ in }
        ) { user in
            UserRowView(user: user, classGroupName: "ひまわり組")
        }
        .navigationTitle("利用者一覧")
    }
}
