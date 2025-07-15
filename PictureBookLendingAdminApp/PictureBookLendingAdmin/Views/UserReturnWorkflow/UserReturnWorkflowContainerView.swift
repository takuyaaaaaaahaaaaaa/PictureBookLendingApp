import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 園児から始まる返却・履歴ワークフローのコンテナビュー
///
/// 組選択 → 園児選択 → 返却・履歴管理の流れを管理します
struct UserReturnWorkflowContainerView: View {
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var selectedClassGroup: ClassGroup?
    @State private var selectedUser: User?
    @State private var isUserListPresented = false
    @State private var isUserDetailPresented = false
    @State private var alertState = AlertState()
    
    var body: some View {
        NavigationStack {
            GroupSelectionForReturnView(
                classGroups: classGroupModel.classGroups,
                onSelectGroup: handleGroupSelection
            )
            .navigationTitle("返却・履歴")
            .task {
                await loadData()
            }
            .sheet(isPresented: $isUserListPresented) {
                UserListFromGroupView(
                    users: filteredUsers,
                    classGroup: selectedClassGroup,
                    onSelectUser: handleUserSelection,
                    onCancel: { isUserListPresented = false }
                )
            }
            .sheet(isPresented: $isUserDetailPresented) {
                UserDetailForReturnView(
                    user: selectedUser,
                    loans: filteredLoans,
                    onReturn: handleReturn,
                    onCancel: { isUserDetailPresented = false }
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
    
    private var filteredLoans: [Loan] {
        guard let selectedUser else { return [] }
        return lendingModel.loans.filter { $0.userId == selectedUser.id }
    }
    
    private func handleGroupSelection(_ classGroup: ClassGroup) {
        selectedClassGroup = classGroup
        isUserListPresented = true
    }
    
    private func handleUserSelection(_ user: User) {
        selectedUser = user
        isUserListPresented = false
        isUserDetailPresented = true
    }
    
    private func handleReturn(_ loan: Loan) {
        Task {
            await performReturn(loan)
        }
    }
    
    private func performReturn(_ loan: Loan) async {
        do {
            try await lendingModel.returnBook(loanId: loan.id)
            alertState = AlertState(
                title: "返却完了",
                message: "絵本を返却しました。",
                isPresented: true
            )
        } catch {
            alertState = AlertState(
                title: "返却エラー",
                message: "返却処理中にエラーが発生しました。",
                isPresented: true
            )
        }
    }
    
    private func loadData() async {
        do {
            try await classGroupModel.loadAllClassGroups()
            try await userModel.loadUsers()
            try await lendingModel.loadAllLoans()
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

struct GroupSelectionForReturnView: View {
    let classGroups: [ClassGroup]
    let onSelectGroup: (ClassGroup) -> Void
    
    var body: some View {
        List(classGroups) { group in
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                Text("\(group.ageGroup)歳児クラス")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(group.year)年度")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelectGroup(group)
            }
        }
    }
}

struct UserListFromGroupView: View {
    let users: [User]
    let classGroup: ClassGroup?
    let onSelectUser: (User) -> Void
    let onCancel: () -> Void
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List(filteredUsers) { user in
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                    if let classGroup = classGroup {
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
            .navigationTitle(classGroup?.name ?? "園児一覧")
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

struct UserDetailForReturnView: View {
    let user: User?
    let loans: [Loan]
    let onReturn: (Loan) -> Void
    let onCancel: () -> Void
    
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                if let user = user {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                }
                
                Picker("表示内容", selection: $selectedSegment) {
                    Text("貸出中").tag(0)
                    Text("履歴").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    ForEach(filteredLoans) { loan in
                        LoanRowView(
                            loan: loan,
                            showReturnButton: selectedSegment == 0 && loan.returnedAt == nil,
                            onReturn: onReturn
                        )
                    }
                }
            }
            .navigationTitle("詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onCancel)
                }
            }
        }
    }
    
    private var filteredLoans: [Loan] {
        switch selectedSegment {
        case 0:
            return loans.filter { $0.returnedDate == nil }
        case 1:
            return loans.sorted { $0.loanDate > $1.loanDate }
        default:
            return loans
        }
    }
}

struct LoanRowView: View {
    let loan: Loan
    let showReturnButton: Bool
    let onReturn: (Loan) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("貸出日: \(loan.loanDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                    Text("返却予定: \(loan.dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(loan.isOverdue ? .red : .secondary)
                    if let returnedDate = loan.returnedDate {
                        Text("返却日: \(returnedDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
                
                Spacer()
                
                if showReturnButton {
                    Button("返却") {
                        onReturn(loan)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            if loan.isOverdue && loan.returnedDate == nil {
                Text("⚠️ 返却期限を過ぎています")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    UserReturnWorkflowContainerView()
        .environment(UserModel(repository: MockRepositoryFactory().userRepository))
        .environment(ClassGroupModel(repository: MockRepositoryFactory().classGroupRepository))
        .environment(LendingModel(
            repository: MockRepositoryFactory().loanRepository,
            bookRepository: MockRepositoryFactory().bookRepository,
            userRepository: MockRepositoryFactory().userRepository
        ))
}