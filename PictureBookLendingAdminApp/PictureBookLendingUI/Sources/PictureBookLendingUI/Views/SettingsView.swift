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
    let onSelectLoanSettings: () -> Void
    let onSelectDeviceReset: () -> Void
    
    public init(
        classGroupCount: Int,
        userCount: Int,
        bookCount: Int,
        loanPeriodDays: Int,
        maxBooksPerUser: Int,
        onSelectUser: @escaping () -> Void,
        onSelectLoanSettings: @escaping () -> Void,
        onSelectDeviceReset: @escaping () -> Void
    ) {
        self.classGroupCount = classGroupCount
        self.userCount = userCount
        self.bookCount = bookCount
        self.loanPeriodDays = loanPeriodDays
        self.maxBooksPerUser = maxBooksPerUser
        self.onSelectUser = onSelectUser
        self.onSelectLoanSettings = onSelectLoanSettings
        self.onSelectDeviceReset = onSelectDeviceReset
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            SettingsMenuItem(
                iconName: "person",
                title: "利用者管理",
                subtitle: "\(classGroupCount)組・\(userCount)人登録済み",
                action: onSelectUser
            )
            
            HStack {
                Image(systemName: "book")
                    .font(.title2)
                    .frame(width: 30)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("絵本管理")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("\(bookCount)冊登録済み・メイン画面で編集モードを利用してください")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(.gray.opacity(0.05))
            .cornerRadius(12)
            
            SettingsMenuItem(
                iconName: "clock",
                title: "貸出設定",
                subtitle: "貸出期間：\(loanPeriodDays)日 / 一人\(maxBooksPerUser)冊まで貸出可能",
                action: onSelectLoanSettings
            )
            
            Divider()
                .padding(.vertical, 8)
            
            SettingsMenuItem(
                iconName: "trash.circle",
                title: "端末初期化",
                subtitle: "利用者・絵本・貸出記録のデータを削除",
                action: onSelectDeviceReset,
                style: .destructive
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
    let style: Style
    
    enum Style {
        case normal
        case destructive
        
        var iconColor: Color {
            switch self {
            case .normal: return .primary
            case .destructive: return .red
            }
        }
        
        var titleColor: Color {
            switch self {
            case .normal: return .primary
            case .destructive: return .red
            }
        }
    }
    
    init(
        iconName: String, title: String, subtitle: String, action: @escaping () -> Void,
        style: Style = .normal
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.style = style
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: iconName)
                    .font(.title2)
                    .frame(width: 30)
                    .foregroundStyle(style.iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(style.titleColor)
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
            onSelectLoanSettings: {},
            onSelectDeviceReset: {}
        )
        .navigationTitle("設定")
    }
}
