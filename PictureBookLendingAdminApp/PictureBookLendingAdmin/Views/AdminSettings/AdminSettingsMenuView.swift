import PictureBookLendingDomain
import PictureBookLendingModel
import SwiftUI

/// 管理者設定メニューのビュー
///
/// 管理者向けの各種設定・管理機能へのアクセスメニューを提供します。
/// iPad横向きでの操作に最適化された見やすいグリッドレイアウトを採用します。
struct AdminSettingsMenuView: View {
    @Environment(BookModel.self) private var bookModel
    @Environment(UserModel.self) private var userModel
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(LendingModel.self) private var lendingModel
    
    @State private var alertState = AlertState()
    @State private var isLoading = false
    
    // 統計情報
    @State private var totalBooks = 0
    @State private var totalUsers = 0
    @State private var totalGroups = 0
    @State private var activeLoans = 0
    @State private var overdueLoans = 0
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 200), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 概要統計カード
                overviewStatsCard
                
                // 管理機能グリッド
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(AdminSettingsDestination.allCases, id: \.self) { destination in
                        NavigationLink(value: destination) {
                            AdminMenuCardView(
                                destination: destination,
                                isUrgent: shouldShowUrgent(for: destination)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await loadStats()
        }
        .task {
            await loadStats()
        }
        .alert(alertState.title, isPresented: $alertState.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertState.message)
        }
    }
    
    private var overviewStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("システム概要")
                    .font(.headline)
                Spacer()
            }
            
            if isLoading {
                ProgressView("データを読み込み中...")
                    .frame(height: 80)
            } else {
                HStack(spacing: 20) {
                    StatItemView(
                        title: "絵本",
                        value: "\(totalBooks)",
                        icon: "book.fill",
                        color: .blue
                    )
                    
                    StatItemView(
                        title: "園児",
                        value: "\(totalUsers)",
                        icon: "person.fill",
                        color: .green
                    )
                    
                    StatItemView(
                        title: "組",
                        value: "\(totalGroups)",
                        icon: "person.3.fill",
                        color: .purple
                    )
                    
                    StatItemView(
                        title: "貸出中",
                        value: "\(activeLoans)",
                        icon: "book.and.wrench",
                        color: .orange
                    )
                    
                    if overdueLoans > 0 {
                        StatItemView(
                            title: "期限切れ",
                            value: "\(overdueLoans)",
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func shouldShowUrgent(for destination: AdminSettingsDestination) -> Bool {
        switch destination {
        case .overdueManagement:
            return overdueLoans > 0
        default:
            return false
        }
    }
    
    private func loadStats() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let booksLoad = bookModel.load()
            async let usersLoad = userModel.load()
            async let groupsLoad = classGroupModel.load()
            async let loansLoad = lendingModel.load()
            
            try await booksLoad
            try await usersLoad
            try await groupsLoad
            try await loansLoad
            
            totalBooks = bookModel.books.count
            totalUsers = userModel.users.count
            totalGroups = classGroupModel.classGroups.count
            activeLoans = lendingModel.currentLoans.count
            overdueLoans = lendingModel.currentLoans.filter { $0.dueDate < Date() }.count
        } catch {
            alertState = AlertState(
                title: "読み込みエラー",
                message: "統計情報の読み込みに失敗しました: \(error.localizedDescription)"
            )
        }
    }
}

/// 統計項目ビュー
private struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 管理メニューカードビュー
private struct AdminMenuCardView: View {
    let destination: AdminSettingsDestination
    let isUrgent: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: destination.iconName)
                    .font(.title2)
                    .foregroundStyle(color)
                
                if isUrgent {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .background(Circle().fill(.white))
                        .offset(x: 20, y: -20)
                }
            }
            
            Text(destination.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            if isUrgent {
                Text("要確認")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fontWeight(.medium)
            }
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUrgent ? Color.red.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isUrgent ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isUrgent)
    }
    
    private var color: Color {
        switch destination {
        case .groupManagement: .purple
        case .userManagement: .green
        case .bookManagement: .blue
        case .statistics: .orange
        case .overdueManagement: isUrgent ? .red : .orange
        case .appSettings: .gray
        case .dataSync: .indigo
        }
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let userModel = UserModel(repository: mockFactory.userRepository)
    let classGroupModel = ClassGroupModel(repository: mockFactory.classGroupRepository)
    let lendingModel = LendingModel(
        repository: mockFactory.loanRepository,
        bookRepository: mockFactory.bookRepository,
        userRepository: mockFactory.userRepository
    )
    
    NavigationStack {
        AdminSettingsMenuView()
            .environment(bookModel)
            .environment(userModel)
            .environment(classGroupModel)
            .environment(lendingModel)
            .navigationTitle("管理者設定")
    }
}