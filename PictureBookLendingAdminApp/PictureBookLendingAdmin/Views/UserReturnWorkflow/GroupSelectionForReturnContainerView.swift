import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 返却用組選択のコンテナビュー
///
/// 返却・履歴確認を行う園児の組を選択する画面です。
/// 各組の園児数と現在の貸出状況を表示し、効率的な組選択をサポートします。
struct GroupSelectionForReturnContainerView: View {
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LendingModel.self) private var lendingModel
    @Environment(UserModel.self) private var userModel
    
    @State private var alertState = AlertState()
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー説明
            HStack {
                Image(systemName: "person.badge.clock")
                    .foregroundStyle(.blue)
                Text("返却・履歴確認を行う組を選択してください")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // 組一覧
            if isLoading {
                LoadingView(message: "組情報を読み込み中...")
            } else if classGroupModel.classGroups.isEmpty {
                EmptyStateView(
                    title: "組が登録されていません",
                    message: "まず管理者設定から組を登録してください。",
                    systemImage: "person.3.fill"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(classGroupModel.classGroups) { group in
                            NavigationLink(value: group) {
                                GroupReturnCardView(
                                    group: group,
                                    activeLoanCount: activeLoanCount(for: group)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private func activeLoanCount(for group: ClassGroup) -> Int {
        let groupUserIds = userModel.users
            .filter { $0.classGroupId == group.id }
            .map { $0.id }
        
        return lendingModel.currentLoans
            .filter { loan in groupUserIds.contains(loan.userId) }
            .count
    }
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let groupsLoad = classGroupModel.load()
            async let usersLoad = userModel.load()
            async let loansLoad = lendingModel.load()
            
            try await groupsLoad
            try await usersLoad
            try await loansLoad
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "データの読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 返却用組カードビュー
private struct GroupReturnCardView: View {
    let group: ClassGroup
    let activeLoanCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(group.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 16) {
                    Label("\(group.userCount)人", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if activeLoanCount > 0 {
                        Label("\(activeLoanCount)冊貸出中", systemImage: "book.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Label("貸出なし", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                if activeLoanCount > 0 {
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
                .stroke(activeLoanCount > 0 ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
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
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    let userModel = UserModel(repository: mockFactory.userRepository)
    
    NavigationStack {
        GroupSelectionForReturnContainerView()
            .environment(classGroupModel)
            .environment(lendingModel)
            .environment(userModel)
    }
}