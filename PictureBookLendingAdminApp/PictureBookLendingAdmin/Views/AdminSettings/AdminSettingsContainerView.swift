import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 管理者設定のコンテナビュー
///
/// 管理者向けの設定・データ管理機能を提供します
struct AdminSettingsContainerView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var selectedSettingsItem: SettingsItem?
    @State private var isSettingsDetailPresented = false
    @State private var alertState = AlertState()
    
    var body: some View {
        NavigationStack {
            List {
                Section("データ管理") {
                    ForEach(SettingsItem.dataManagementItems) { item in
                        SettingsRowView(item: item, onTap: handleSettingsItemTap)
                    }
                }
                
                Section("統計情報") {
                    ForEach(SettingsItem.statisticsItems) { item in
                        SettingsRowView(item: item, onTap: handleSettingsItemTap)
                    }
                }
                
                Section("アプリ設定") {
                    ForEach(SettingsItem.appSettingsItems) { item in
                        SettingsRowView(item: item, onTap: handleSettingsItemTap)
                    }
                }
            }
            .navigationTitle("設定")
            .task {
                await loadData()
            }
            .sheet(isPresented: $isSettingsDetailPresented) {
                SettingsDetailView(
                    item: selectedSettingsItem,
                    onDismiss: { isSettingsDetailPresented = false }
                )
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertState.message)
            }
        }
    }
    
    private func handleSettingsItemTap(_ item: SettingsItem) {
        selectedSettingsItem = item
        isSettingsDetailPresented = true
    }
    
    private func loadData() async {
        do {
            try await bookModel.loadBooks()
            try await userModel.loadUsers()
            try await classGroupModel.loadAllClassGroups()
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

// MARK: - Supporting Types

struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let type: SettingsType
    
    static let dataManagementItems: [SettingsItem] = [
        SettingsItem(title: "組管理", systemImage: "person.3", type: .classGroupManagement),
        SettingsItem(title: "園児管理", systemImage: "person.2", type: .userManagement),
        SettingsItem(title: "絵本管理", systemImage: "book", type: .bookManagement)
    ]
    
    static let statisticsItems: [SettingsItem] = [
        SettingsItem(title: "統計情報", systemImage: "chart.bar", type: .statistics),
        SettingsItem(title: "期限切れ管理", systemImage: "exclamationmark.triangle", type: .overdueManagement)
    ]
    
    static let appSettingsItems: [SettingsItem] = [
        SettingsItem(title: "アプリ設定", systemImage: "gearshape", type: .appSettings),
        SettingsItem(title: "データ同期", systemImage: "arrow.triangle.2.circlepath", type: .dataSync)
    ]
}

enum SettingsType {
    case classGroupManagement
    case userManagement
    case bookManagement
    case statistics
    case overdueManagement
    case appSettings
    case dataSync
}

// MARK: - Supporting Views

struct SettingsRowView: View {
    let item: SettingsItem
    let onTap: (SettingsItem) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: item.systemImage)
                .foregroundStyle(.blue)
                .frame(width: 24, height: 24)
            
            Text(item.title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(item)
        }
    }
}

struct SettingsDetailView: View {
    let item: SettingsItem?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            Group {
                if let item = item {
                    settingsDetailContent(for: item.type)
                } else {
                    Text("設定項目が選択されていません")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(item?.title ?? "設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる", action: onDismiss)
                }
            }
        }
    }
    
    @ViewBuilder
    private func settingsDetailContent(for type: SettingsType) -> some View {
        switch type {
        case .classGroupManagement:
            ClassGroupManagementView(onDismiss: onDismiss)
        case .userManagement:
            UserManagementView(onDismiss: onDismiss)
        case .bookManagement:
            BookManagementView(onDismiss: onDismiss)
        case .statistics:
            StatisticsView()
        case .overdueManagement:
            OverdueManagementView()
        case .appSettings:
            AppSettingsView()
        case .dataSync:
            DataSyncView()
        }
    }
}

struct ClassGroupManagementView: View {
    @Environment(ClassGroupModel.self) private var classGroupModel
    let onDismiss: () -> Void
    
    var body: some View {
        List(classGroupModel.classGroups) { group in
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
        }
    }
}

struct UserManagementView: View {
    @Environment(UserModel.self) private var userModel
    let onDismiss: () -> Void
    
    var body: some View {
        List(userModel.users) { user in
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text("ID: \(user.id.uuidString.prefix(8))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct BookManagementView: View {
    @Environment(BookModel.self) private var bookModel
    let onDismiss: () -> Void
    
    var body: some View {
        List(bookModel.books) { book in
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                Text("著者: \(book.author)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("対象年齢: \(book.targetAge)歳〜")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

struct StatisticsView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(LendingModel.self) private var lendingModel
    
    var body: some View {
        List {
            Section("基本統計") {
                StatisticsRowView(
                    title: "総絵本数",
                    value: "\(bookModel.books.count)冊",
                    systemImage: "book"
                )
                
                StatisticsRowView(
                    title: "総園児数",
                    value: "\(userModel.users.count)人",
                    systemImage: "person.2"
                )
                
                StatisticsRowView(
                    title: "貸出中",
                    value: "\(activeLoanCount)件",
                    systemImage: "arrow.right"
                )
                
                StatisticsRowView(
                    title: "期限切れ",
                    value: "\(overdueLoanCount)件",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
    }
    
    private var activeLoanCount: Int {
        lendingModel.loans.filter { $0.returnedDate == nil }.count
    }
    
    private var overdueLoanCount: Int {
        lendingModel.loans.filter { $0.isOverdue && $0.returnedDate == nil }.count
    }
}

struct StatisticsRowView: View {
    let title: String
    let value: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct OverdueManagementView: View {
    @Environment(LendingModel.self) private var lendingModel
    
    var body: some View {
        List(overdueLoans) { loan in
            VStack(alignment: .leading, spacing: 4) {
                Text("期限切れ")
                    .font(.headline)
                    .foregroundStyle(.red)
                Text("貸出日: \(loan.loanDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                Text("返却予定: \(loan.dueDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var overdueLoans: [Loan] {
        lendingModel.loans.filter { $0.isOverdue && $0.returnedDate == nil }
    }
}

struct AppSettingsView: View {
    var body: some View {
        List {
            Section("アプリ設定") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct DataSyncView: View {
    var body: some View {
        List {
            Section("データ同期") {
                Button("すべてのデータを同期") {
                    // 同期処理の実装
                }
            }
        }
    }
}

#Preview {
    AdminSettingsContainerView()
        .environment(BookModel(repository: MockRepositoryFactory().bookRepository))
        .environment(UserModel(repository: MockRepositoryFactory().userRepository))
        .environment(ClassGroupModel(repository: MockRepositoryFactory().classGroupRepository))
        .environment(LendingModel(
            repository: MockRepositoryFactory().loanRepository,
            bookRepository: MockRepositoryFactory().bookRepository,
            userRepository: MockRepositoryFactory().userRepository
        ))
}