import PictureBookLendingDomain
import SwiftUI

/// 利用者一覧のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct UserListView: View {
    let users: [User]
    let searchText: Binding<String>
    let onDelete: (IndexSet) -> Void
    
    public init(
        users: [User],
        searchText: Binding<String>,
        onDelete: @escaping (IndexSet) -> Void
    ) {
        self.users = users
        self.searchText = searchText
        self.onDelete = onDelete
    }
    
    public var body: some View {
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
                        UserRowView(user: user)
                    }
                }
                .onDelete(perform: onDelete)
            }
            .searchable(text: searchText, prompt: "名前またはグループで検索")
        }
    }
}

/// 利用者リスト行ビュー
///
/// 一覧の各行に表示する利用者情報のレイアウトを定義します。
public struct UserRowView: View {
    let user: User
    
    public init(user: User) {
        self.user = user
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            Text(user.name)
                .font(.headline)
            Text("組情報")
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
        )
        .navigationTitle("利用者一覧")
    }
}
