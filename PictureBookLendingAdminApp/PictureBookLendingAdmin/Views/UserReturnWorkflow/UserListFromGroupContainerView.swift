import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 組内園児一覧のコンテナビュー
///
/// 選択された組の園児一覧を表示し、返却・履歴確認を行う園児を選択する画面です。
/// 各園児の貸出状況を表示し、効率的な園児選択をサポートします。
struct UserListFromGroupContainerView: View {
    let group: ClassGroup
    
    @Environment(UserModel.self) private var userModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var searchText = ""
    @State private var selectedFilter: UserFilter = .all
    @State private var alertState = AlertState()
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 組情報ヘッダー
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(.green)
                    Text(group.name)
                        .font(.headline)
                    Spacer()
                    Text("\(filteredUsers.count)人")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("返却・履歴確認を行う園児を選択してください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // 検索・フィルタ UI
            SearchAndFilterBarView(
                searchText: $searchText,
                searchPlaceholder: "園児名で検索",
                selectedFilter: $selectedFilter,
                filterOptions: UserFilter.allCases
            )
            
            // 園児一覧
            if isLoading {
                LoadingView(message: "園児情報を読み込み中...")
            } else if filteredUsers.isEmpty {
                EmptyStateView(
                    title: "園児が見つかりません",
                    message: searchText.isEmpty ? 
                        "\(group.name)に登録されている園児がありません。" :
                        "「\(searchText)」に一致する園児が見つかりません。",
                    systemImage: "person.fill.questionmark"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredUsers) { user in
                            NavigationLink(value: UserReturnDestination.userDetail(user)) {
                                UserReturnCardView(
                                    user: user,
                                    activeLoanCount: activeLoanCount(for: user),
                                    overdueLoanCount: overdueLoanCount(for: user)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadUsers()
        }
        .task {
            await loadUsers()
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private var filteredUsers: [User] {
        let groupUsers = userModel.users.filter { $0.classGroupId == group.id }
        
        let searchFiltered = searchText.isEmpty ? groupUsers : groupUsers.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText)
        }
        
        return selectedFilter.apply(to: searchFiltered, lendingModel: lendingModel)
    }
    
    private func activeLoanCount(for user: User) -> Int {
        lendingModel.currentLoans.filter { $0.userId == user.id }.count
    }
    
    private func overdueLoanCount(for user: User) -> Int {
        lendingModel.currentLoans
            .filter { $0.userId == user.id && $0.dueDate < Date() }
            .count
    }
    
    private func loadUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await userModel.load()
            try await lendingModel.load()
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "園児情報の読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 園児フィルタ用列挙型
enum UserFilter: String, CaseIterable {
    case all = "すべて"
    case withLoans = "貸出中"
    case overdue = "期限切れ"
    case noLoans = "貸出なし"
    
    func apply(to users: [User], lendingModel: LendingModel) -> [User] {
        switch self {
        case .all:
            return users
        case .withLoans:
            return users.filter { user in
                lendingModel.currentLoans.contains { $0.userId == user.id }
            }
        case .overdue:
            return users.filter { user in
                lendingModel.currentLoans.contains { loan in
                    loan.userId == user.id && loan.dueDate < Date()
                }
            }
        case .noLoans:
            return users.filter { user in
                !lendingModel.currentLoans.contains { $0.userId == user.id }
            }
        }
    }
}

/// 返却用園児カードビュー
private struct UserReturnCardView: View {
    let user: User
    let activeLoanCount: Int
    let overdueLoanCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(user.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 16) {
                    Text("年齢: \(user.age)歳")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if activeLoanCount > 0 {
                        if overdueLoanCount > 0 {
                            Label("\(overdueLoanCount)冊期限切れ", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else {
                            Label("\(activeLoanCount)冊貸出中", systemImage: "book.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Label("貸出なし", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                if overdueLoanCount > 0 {
                    Text("\(overdueLoanCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.red)
                    Text("期限切れ")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if activeLoanCount > 0 {
                    Text("\(activeLoanCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    Text("貸出中")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    overdueLoanCount > 0 ? Color.red.opacity(0.3) :
                    activeLoanCount > 0 ? Color.orange.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
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
    let userModel = UserModel(repository: mockFactory.userRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    let sampleGroup = ClassGroup(
        id: UUID(),
        name: "ひまわり組",
        userCount: 20
    )
    
    NavigationStack {
        UserListFromGroupContainerView(group: sampleGroup)
            .environment(userModel)
            .environment(lendingModel)
    }
}