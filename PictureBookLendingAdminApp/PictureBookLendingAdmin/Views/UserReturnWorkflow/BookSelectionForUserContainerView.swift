import PictureBookLendingDomain
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 園児指定での絵本選択のコンテナビュー
///
/// 特定の園児に新しい絵本を貸し出すための絵本選択画面です。
/// 園児の年齢に適した絵本を優先表示し、効率的な選択をサポートします。
struct BookSelectionForUserContainerView: View {
    let user: User
    
    @Environment(BookModel.self) private var bookModel
    @Environment(LendingModel.self) private var lendingModel
    @Environment(\.navigationPath) private var navigationPath
    
    @State private var searchText = ""
    @State private var selectedFilter: BookSelectionFilter = .suitable
    @State private var alertState = AlertState()
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 園児情報ヘッダー
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.blue)
                    Text("\(user.name)くん/ちゃんに貸し出す絵本を選択")
                        .font(.headline)
                    Spacer()
                }
                
                HStack {
                    Text("年齢: \(user.age)歳")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(filteredBooks.count)冊見つかりました")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // 検索・フィルタ UI
            SearchAndFilterBarView(
                searchText: $searchText,
                searchPlaceholder: "絵本タイトル・著者で検索",
                selectedFilter: $selectedFilter,
                filterOptions: BookSelectionFilter.allCases
            )
            
            // 絵本一覧
            if isLoading {
                LoadingView(message: "絵本を読み込み中...")
            } else if filteredBooks.isEmpty {
                EmptyStateView(
                    title: "絵本が見つかりません",
                    message: searchText.isEmpty ? 
                        "条件に一致する絵本がありません。フィルタを変更してみてください。" :
                        "「\(searchText)」に一致する絵本が見つかりません。",
                    systemImage: "book.fill"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredBooks) { book in
                            BookSelectionCardView(
                                book: book,
                                user: user,
                                isLoaned: lendingModel.isBookCurrentlyLoaned(book.id),
                                onSelect: { handleBookSelection(book) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("絵本選択")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadBooks()
        }
        .task {
            await loadBooks()
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private var filteredBooks: [Book] {
        let searchFiltered = searchText.isEmpty ? bookModel.books : bookModel.books.filter { book in
            book.title.localizedCaseInsensitiveContains(searchText) ||
            book.author.localizedCaseInsensitiveContains(searchText)
        }
        
        return selectedFilter.apply(to: searchFiltered, userAge: user.age, lendingModel: lendingModel)
    }
    
    private func handleBookSelection(_ book: Book) {
        // 貸出中の絵本は選択不可
        if lendingModel.isBookCurrentlyLoaned(book.id) {
            alertState = AlertState(
                title: "この絵本は貸出中です",
                message: "「\(book.title)」は現在貸出中のため、貸し出すことはできません。"
            )
            return
        }
        
        // 貸出確認画面へ遷移
        navigationPath.wrappedValue.append(UserReturnDestination.lendingConfirmationForUser(book, user))
    }
    
    private func loadBooks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await bookModel.load()
            try await lendingModel.load()
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "絵本データの読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 絵本選択フィルタ用列挙型
enum BookSelectionFilter: String, CaseIterable {
    case suitable = "年齢適合"
    case available = "貸出可能"
    case all = "すべて"
    
    func apply(to books: [Book], userAge: Int, lendingModel: LendingModel) -> [Book] {
        let availableBooks = books.filter { !lendingModel.isBookCurrentlyLoaned($0.id) }
        
        switch self {
        case .suitable:
            // 年齢適合かつ貸出可能な絵本を優先、その後年齢適合の貸出中絵本
            let suitableAvailable = availableBooks.filter { $0.isSuitable(for: userAge) }
            let suitableLoaned = books.filter { $0.isSuitable(for: userAge) && lendingModel.isBookCurrentlyLoaned($0.id) }
            return suitableAvailable + suitableLoaned
        case .available:
            return availableBooks
        case .all:
            return books
        }
    }
}

/// 絵本選択用カードビュー
private struct BookSelectionCardView: View {
    let book: Book
    let user: User
    let isLoaned: Bool
    let onSelect: () -> Void
    
    private var isAgeSuitable: Bool {
        book.isSuitable(for: user.age)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("著者: \(book.author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Text("対象年齢: \(book.targetAge)歳以上")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if isAgeSuitable {
                            Label("適齢", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Label("年齢外", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        
                        if isLoaned {
                            Label("貸出中", systemImage: "person.fill.checkmark")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else {
                            Label("利用可能", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    if isLoaned {
                        Image(systemName: "person.fill.checkmark")
                            .font(.title2)
                            .foregroundStyle(.red)
                        Text("貸出中")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if isAgeSuitable {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("おすすめ")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        Text("年齢外")
                            .font(.caption)
                            .foregroundStyle(.orange)
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
                        isLoaned ? Color.red.opacity(0.3) :
                        isAgeSuitable ? Color.green.opacity(0.3) : Color.orange.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoaned)
        .opacity(isLoaned ? 0.6 : 1.0)
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
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    let sampleUser = User(
        id: UUID(),
        name: "田中太郎",
        age: 5,
        classGroupId: UUID()
    )
    
    NavigationStack {
        BookSelectionForUserContainerView(user: sampleUser)
            .environment(bookModel)
            .environment(lendingModel)
    }
}