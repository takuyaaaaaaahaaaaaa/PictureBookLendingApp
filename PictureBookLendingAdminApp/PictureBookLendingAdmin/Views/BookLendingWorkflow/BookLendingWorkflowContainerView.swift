import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 絵本から始まる貸出ワークフローのコンテナビュー
///
/// 絵本選択 → 組選択 → 園児選択 → 貸出確認の流れを管理します
struct BookLendingWorkflowContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var selectedBook: Book?
    @State private var selectedClassGroup: ClassGroup?
    @State private var selectedUser: User?
    @State private var isGroupSelectionPresented = false
    @State private var isUserSelectionPresented = false
    @State private var isLendingConfirmationPresented = false
    @State private var alertState = AlertState()
    
    var body: some View {
        NavigationStack {
            BookListForLendingView(
                books: bookModel.books,
                onSelectBook: handleBookSelection
            )
            .navigationTitle("絵本から貸出")
            .task {
                await loadBooks()
            }
            .sheet(isPresented: $isGroupSelectionPresented) {
                GroupSelectionForLendingView(
                    classGroups: classGroupModel.classGroups,
                    selectedBook: selectedBook,
                    onSelectGroup: handleGroupSelection,
                    onCancel: { isGroupSelectionPresented = false }
                )
            }
            .sheet(isPresented: $isUserSelectionPresented) {
                UserSelectionForLendingView(
                    users: filteredUsers,
                    selectedBook: selectedBook,
                    selectedClassGroup: selectedClassGroup,
                    onSelectUser: handleUserSelection,
                    onCancel: { isUserSelectionPresented = false }
                )
            }
            .sheet(isPresented: $isLendingConfirmationPresented) {
                LendingConfirmationView(
                    book: selectedBook,
                    user: selectedUser,
                    onConfirm: handleLendingConfirmation,
                    onCancel: { isLendingConfirmationPresented = false }
                )
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertState.message)
            }
        }
    }
    
    private var filteredUsers: [User] {
        guard let selectedClassGroup else { return [] }
        return userModel.users.filter { $0.classGroupId == selectedClassGroup.id }
    }
    
    private func handleBookSelection(_ book: Book) {
        selectedBook = book
        isGroupSelectionPresented = true
    }
    
    private func handleGroupSelection(_ classGroup: ClassGroup) {
        selectedClassGroup = classGroup
        isGroupSelectionPresented = false
        isUserSelectionPresented = true
    }
    
    private func handleUserSelection(_ user: User) {
        selectedUser = user
        isUserSelectionPresented = false
        isLendingConfirmationPresented = true
    }
    
    private func handleLendingConfirmation() {
        Task {
            await performLending()
        }
    }
    
    private func performLending() async {
        guard let book = selectedBook,
              let user = selectedUser else { return }
        
        do {
            try await lendingModel.lendBook(bookId: book.id, userId: user.id)
            isLendingConfirmationPresented = false
            resetSelection()
            alertState = AlertState(
                title: "貸出完了",
                message: "「\(book.title)」を\(user.name)さんに貸出しました。",
                isPresented: true
            )
        } catch {
            alertState = AlertState(
                title: "貸出エラー",
                message: "貸出処理中にエラーが発生しました。",
                isPresented: true
            )
        }
    }
    
    private func resetSelection() {
        selectedBook = nil
        selectedClassGroup = nil
        selectedUser = nil
    }
    
    private func loadBooks() async {
        do {
            try await bookModel.loadBooks()
            try await classGroupModel.loadAllClassGroups()
            try await userModel.loadUsers()
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "データの読み込みに失敗しました。",
                isPresented: true
            )
        }
    }
}

// MARK: - Supporting Views

struct BookListForLendingView: View {
    let books: [Book]
    let onSelectBook: (Book) -> Void
    
    @State private var searchText = ""
    
    var body: some View {
        List(filteredBooks) { book in
            BookRowForLendingView(book: book, onTap: onSelectBook)
        }
        .searchable(text: $searchText, prompt: "絵本を検索")
    }
    
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { 
                $0.title.contains(searchText) || $0.author.contains(searchText) 
            }
        }
    }
}

struct BookRowForLendingView: View {
    let book: Book
    let onTap: (Book) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.title)
                .font(.headline)
            Text(book.author)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("対象年齢: \(book.targetAge)歳〜")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(book)
        }
    }
}

struct GroupSelectionForLendingView: View {
    let classGroups: [ClassGroup]
    let selectedBook: Book?
    let onSelectGroup: (ClassGroup) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            List(classGroups) { group in
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                    Text("\(group.ageGroup)歳児クラス")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelectGroup(group)
                }
            }
            .navigationTitle("組を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onCancel)
                }
            }
        }
    }
}

struct UserSelectionForLendingView: View {
    let users: [User]
    let selectedBook: Book?
    let selectedClassGroup: ClassGroup?
    let onSelectUser: (User) -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List(filteredUsers) { user in
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                    if let classGroup = selectedClassGroup {
                        Text(classGroup.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelectUser(user)
                }
            }
            .searchable(text: $searchText, prompt: "園児を検索")
            .navigationTitle("園児を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onCancel)
                }
            }
        }
    }
    
    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { $0.name.contains(searchText) }
        }
    }
}

struct LendingConfirmationView: View {
    let book: Book?
    let user: User?
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text("貸出確認")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let book = book {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("絵本")
                                .font(.headline)
                            Text(book.title)
                                .font(.title3)
                            Text("著者: \(book.author)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    if let user = user {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("貸出先")
                                .font(.headline)
                            Text(user.name)
                                .font(.title3)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                VStack(spacing: 12) {
                    Button("貸出を確定", action: onConfirm)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    
                    Button("キャンセル", action: onCancel)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("貸出確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onCancel)
                }
            }
        }
    }
}

#Preview {
    BookLendingWorkflowContainerView()
        .environment(BookModel(repository: MockRepositoryFactory().bookRepository))
        .environment(UserModel(repository: MockRepositoryFactory().userRepository))
        .environment(ClassGroupModel(repository: MockRepositoryFactory().classGroupRepository))
        .environment(LendingModel(
            repository: MockRepositoryFactory().loanRepository,
            bookRepository: MockRepositoryFactory().bookRepository,
            userRepository: MockRepositoryFactory().userRepository
        ))
}