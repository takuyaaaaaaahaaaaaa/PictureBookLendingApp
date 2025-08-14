import PictureBookLendingDomain
import SwiftUI

/// 利用者一覧のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct UserListView<RowContent: View>: View {
    let users: [User]
    let searchText: Binding<String>
    let onDelete: (IndexSet) -> Void
    let rowContent: (User) -> RowContent
    
    public init(
        users: [User],
        searchText: Binding<String>,
        onDelete: @escaping (IndexSet) -> Void,
        @ViewBuilder rowContent: @escaping (User) -> RowContent
    ) {
        self.users = users
        self.searchText = searchText
        self.onDelete = onDelete
        self.rowContent = rowContent
    }
    
    public var body: some View {
        Group {
            if users.isEmpty {
                ContentUnavailableView(
                    "利用者がいません",
                    systemImage: "person.slash",
                    description: Text("右上の＋ボタンから利用者を登録してください")
                )
            } else {
                List {
                    ForEach(users) { user in
                        NavigationLink(value: user) {
                            rowContent(user)
                        }
                    }
                    .onDelete(perform: onDelete)
                }
            }
        }
        .searchable(text: searchText, prompt: "名前またはグループで検索")
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
        VStack(alignment: .leading) {
            Text(user.name)
                .font(.headline)
            Text(classGroupName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let user1 = User(name: "山田太郎", classGroupId: UUID())
    let user2 = User(name: "鈴木花子", classGroupId: UUID())
    
    NavigationStack {
        UserListView(
            users: [user1, user2],
            searchText: .constant(""),
            onDelete: { _ in }
        ) { user in
            UserRowView(user: user, classGroupName: "ひまわり組")
        }
        .navigationTitle("利用者一覧")
    }
}
