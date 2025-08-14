import SwiftUI

/// 設定画面のPresentation View
///
/// 管理者用の設定メニューを表示します。
/// NavigationStackや画面遷移はContainer Viewに委譲します。
public struct SettingsView: View {
    let classGroupCount: Int
    let userCount: Int
    let bookCount: Int
    let loanPeriodDays: Int
    let maxBooksPerUser: Int
    let onSelectUser: () -> Void
    let onSelectBook: () -> Void
    let onSelectLoanSettings: () -> Void
    
    public init(
        classGroupCount: Int,
        userCount: Int,
        bookCount: Int,
        loanPeriodDays: Int,
        maxBooksPerUser: Int,
        onSelectUser: @escaping () -> Void,
        onSelectBook: @escaping () -> Void,
        onSelectLoanSettings: @escaping () -> Void
    ) {
        self.classGroupCount = classGroupCount
        self.userCount = userCount
        self.bookCount = bookCount
        self.loanPeriodDays = loanPeriodDays
        self.maxBooksPerUser = maxBooksPerUser
        self.onSelectUser = onSelectUser
        self.onSelectBook = onSelectBook
        self.onSelectLoanSettings = onSelectLoanSettings
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            SettingsMenuItem(
                iconName: "person",
                title: "利用者管理",
                subtitle: "\(classGroupCount)組・\(userCount)人登録済み",
                action: onSelectUser
            )
            
            SettingsMenuItem(
                iconName: "book",
                title: "絵本管理",
                subtitle: "\(bookCount)冊登録済み",
                action: onSelectBook
            )
            
            SettingsMenuItem(
                iconName: "clock",
                title: "貸出設定",
                subtitle: "貸出期間：\(loanPeriodDays)日 / 一人\(maxBooksPerUser)冊まで貸出可能",
                action: onSelectLoanSettings
            )
            
            Spacer()
        }
        .padding()
        .background(.white)
    }
}

/// 設定画面のメニューアイテム
private struct SettingsMenuItem: View {
    let iconName: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: iconName)
                    .font(.title2)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            classGroupCount: 3,
            userCount: 25,
            bookCount: 120,
            loanPeriodDays: 14,
            maxBooksPerUser: 1,
            onSelectUser: {},
            onSelectBook: {},
            onSelectLoanSettings: {}
        )
        .navigationTitle("設定")
    }
}
