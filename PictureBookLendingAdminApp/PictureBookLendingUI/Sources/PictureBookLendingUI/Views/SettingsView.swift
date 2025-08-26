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
    let onSelectBookBulkRegistration: () -> Void
    let onSelectLoanSettings: () -> Void
    let onCreateGuardiansForAllChildren: () -> Void
    let onSelectDeviceReset: () -> Void
    
    public init(
        classGroupCount: Int,
        userCount: Int,
        bookCount: Int,
        loanPeriodDays: Int,
        maxBooksPerUser: Int,
        onSelectUser: @escaping () -> Void,
        onSelectBook: @escaping () -> Void,
        onSelectBookBulkRegistration: @escaping () -> Void,
        onSelectLoanSettings: @escaping () -> Void,
        onCreateGuardiansForAllChildren: @escaping () -> Void,
        onSelectDeviceReset: @escaping () -> Void
    ) {
        self.classGroupCount = classGroupCount
        self.userCount = userCount
        self.bookCount = bookCount
        self.loanPeriodDays = loanPeriodDays
        self.maxBooksPerUser = maxBooksPerUser
        self.onSelectUser = onSelectUser
        self.onSelectBook = onSelectBook
        self.onSelectBookBulkRegistration = onSelectBookBulkRegistration
        self.onSelectLoanSettings = onSelectLoanSettings
        self.onCreateGuardiansForAllChildren = onCreateGuardiansForAllChildren
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
                action: onSelectLoanSettings,
                showChevron: false
            )
            
            Divider()
                .padding(.vertical, 8)
            
            // お試し機能セクション
            VStack(alignment: .leading, spacing: 8) {
                Text("お試し機能")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                SettingsMenuItem(
                    iconName: "person.2.badge.plus",
                    title: "全園児に保護者を作成",
                    subtitle: "現在登録中の園児すべてに対して保護者を自動作成",
                    action: onCreateGuardiansForAllChildren,
                    showChevron: false
                )
                
                SettingsMenuItem(
                    iconName: "books.vertical",
                    title: "絵本一括登録",
                    subtitle: "CSVファイルから複数の絵本を一括登録",
                    action: onSelectBookBulkRegistration,
                    showChevron: false
                )
            }
            
            Divider()
                .padding(.vertical, 8)
            
            SettingsMenuItem(
                iconName: "trash.circle",
                title: "端末初期化",
                subtitle: "利用者・絵本・貸出記録のデータを削除",
                action: onSelectDeviceReset,
                style: .destructive,
                showChevron: false
            )
            
            Spacer()
        }
        .padding()
        .background(.regularMaterial)
    }
}

/// 設定画面のメニューアイテム
private struct SettingsMenuItem: View {
    let iconName: String
    let title: String
    let subtitle: String
    let action: () -> Void
    let style: Style
    let showChevron: Bool
    
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
        style: Style = .normal, showChevron: Bool = true
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.style = style
        self.showChevron = showChevron
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
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
            onSelectBookBulkRegistration: {},
            onSelectLoanSettings: {},
            onCreateGuardiansForAllChildren: {},
            onSelectDeviceReset: {}
        )
        .navigationTitle("設定")
    }
}
