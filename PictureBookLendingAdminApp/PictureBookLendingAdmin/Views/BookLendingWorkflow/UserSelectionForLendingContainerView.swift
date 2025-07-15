import PictureBookLendingDomain
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 貸出用園児選択のコンテナビュー
///
/// 選択された組の園児一覧から、絵本を貸し出す園児を選択する画面です。
/// 園児の年齢と絵本の対象年齢の適合性を表示し、適切な選択をサポートします。
struct UserSelectionForLendingContainerView: View {
    let book: Book
    let group: ClassGroup
    
    @Environment(UserModel.self) private var userModel
    @Environment(LendingModel.self) private var lendingModel
    @Environment(\.navigationPath) private var navigationPath
    
    @State private var searchText = ""
    @State private var alertState = AlertState()
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 選択中の絵本・組情報
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.blue)
                    Text("「\(book.title)」")
                        .font(.headline)
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(.green)
                    Text("\(group.name)の園児から選択してください")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // 検索バー
            if !filteredUsers.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("園児名で検索", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    if !searchText.isEmpty {
                        Button("クリア") {
                            searchText = ""
                        }
                        .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)
            }
            
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
                            UserSelectionCardView(
                                user: user,
                                book: book,
                                onSelect: { handleUserSelection(user) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("\(group.name)の園児")
        .navigationBarTitleDisplayMode(.large)
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
        
        if searchText.isEmpty {
            return groupUsers
        } else {
            return groupUsers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func handleUserSelection(_ user: User) {
        // 貸出確認画面へ遷移
        navigationPath.wrappedValue.append(BookLendingDestination.lendingConfirmation(book, user))
    }
    
    private func loadUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await userModel.load()
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "園児情報の読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 園児選択用カードビュー
private struct UserSelectionCardView: View {
    let user: User
    let book: Book
    let onSelect: () -> Void
    
    private var isAgeSuitable: Bool {
        book.isSuitable(for: user.age)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        Text("年齢: \(user.age)歳")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if isAgeSuitable {
                            Label("適齢", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Label("対象年齢外", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isAgeSuitable ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
    
    let sampleBook = Book(
        id: UUID(),
        title: "サンプル絵本",
        author: "作者名",
        targetAge: 5,
        publishedAt: Date()
    )
    
    let sampleGroup = ClassGroup(
        id: UUID(),
        name: "ひまわり組",
        userCount: 20
    )
    
    NavigationStack {
        UserSelectionForLendingContainerView(book: sampleBook, group: sampleGroup)
            .environment(userModel)
            .environment(lendingModel)
    }
}