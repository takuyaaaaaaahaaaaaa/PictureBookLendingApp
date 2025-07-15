import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 貸出用組選択のコンテナビュー
///
/// 選択された絵本に対して、どの組の園児に貸し出すかを選択する画面です。
/// 組ごとの園児数と貸出状況を表示し、適切な組選択をサポートします。
struct GroupSelectionForLendingContainerView: View {
    let book: Book
    
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LendingModel.self) private var lendingModel
    @Environment(\.navigationPath) private var navigationPath
    
    @State private var alertState = AlertState()
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 選択中の絵本情報
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.blue)
                Text("「\(book.title)」を貸し出す組を選択してください")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // 組一覧
            if isLoading {
                LoadingView(message: "組情報を読み込み中...")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(classGroupModel.classGroups) { group in
                            GroupSelectionCardView(
                                group: group,
                                onSelect: { handleGroupSelection(group) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("組を選択")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadGroups()
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private func handleGroupSelection(_ group: ClassGroup) {
        // 園児選択画面へ遷移
        navigationPath.wrappedValue.append(BookLendingDestination.userSelection(book, group))
    }
    
    private func loadGroups() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await classGroupModel.load()
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "組情報の読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 組選択用カードビュー
private struct GroupSelectionCardView: View {
    let group: ClassGroup
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("園児数: \(group.userCount)人")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
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
    
    NavigationStack {
        GroupSelectionForLendingContainerView(book: sampleBook)
            .environment(classGroupModel)
            .environment(lendingModel)
    }
}