import SwiftUI

/// 設定画面のPresentation View
///
/// 管理者用の設定メニューを表示します。
/// NavigationStackや画面遷移はContainer Viewに委譲します。
public struct SettingsView: View {
    let classGroupCount: Int
    let userCount: Int
    let bookCount: Int
    let highlightUserManagement: Bool
    let highlightBookManagement: Bool
    let loanPeriodDays: Int
    let maxBooksPerUser: Int
    let coverPreparationStatus: String
    let onSelectCoverPreparation: () -> Void
    let onSelectUser: () -> Void
    let onSelectBook: () -> Void
    let onSelectBookBulkRegistration: () -> Void
    let onSelectLoanSettings: () -> Void
    let onCreateGuardiansForAllChildren: () -> Void
    let onPromoteToNextYear: () -> Void
    let onSelectDeviceReset: () -> Void
    let onSelectFeedback: () -> Void
    let onSelectParentFeedbackQRCode: () -> Void
    let onSelectBackupExport: () -> Void
    let onSelectBackupImport: () -> Void
    let onSelectPrivacy: () -> Void
    let onSelectLicenses: () -> Void

    public init(
        classGroupCount: Int,
        userCount: Int,
        bookCount: Int,
        highlightUserManagement: Bool = false,
        highlightBookManagement: Bool = false,
        loanPeriodDays: Int,
        maxBooksPerUser: Int,
        coverPreparationStatus: String = "準備状況を確認中",
        onSelectCoverPreparation: @escaping () -> Void = {},
        onSelectUser: @escaping () -> Void,
        onSelectBook: @escaping () -> Void,
        onSelectBookBulkRegistration: @escaping () -> Void,
        onSelectLoanSettings: @escaping () -> Void,
        onCreateGuardiansForAllChildren: @escaping () -> Void,
        onPromoteToNextYear: @escaping () -> Void,
        onSelectDeviceReset: @escaping () -> Void,
        onSelectFeedback: @escaping () -> Void,
        onSelectParentFeedbackQRCode: @escaping () -> Void,
        onSelectBackupExport: @escaping () -> Void,
        onSelectBackupImport: @escaping () -> Void,
        onSelectPrivacy: @escaping () -> Void,
        onSelectLicenses: @escaping () -> Void
    ) {
        self.classGroupCount = classGroupCount
        self.userCount = userCount
        self.bookCount = bookCount
        self.highlightUserManagement = highlightUserManagement
        self.highlightBookManagement = highlightBookManagement
        self.loanPeriodDays = loanPeriodDays
        self.maxBooksPerUser = maxBooksPerUser
        self.coverPreparationStatus = coverPreparationStatus
        self.onSelectCoverPreparation = onSelectCoverPreparation
        self.onSelectUser = onSelectUser
        self.onSelectBook = onSelectBook
        self.onSelectBookBulkRegistration = onSelectBookBulkRegistration
        self.onSelectLoanSettings = onSelectLoanSettings
        self.onCreateGuardiansForAllChildren = onCreateGuardiansForAllChildren
        self.onPromoteToNextYear = onPromoteToNextYear
        self.onSelectDeviceReset = onSelectDeviceReset
        self.onSelectFeedback = onSelectFeedback
        self.onSelectParentFeedbackQRCode = onSelectParentFeedbackQRCode
        self.onSelectBackupExport = onSelectBackupExport
        self.onSelectBackupImport = onSelectBackupImport
        self.onSelectPrivacy = onSelectPrivacy
        self.onSelectLicenses = onSelectLicenses
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingsMenuItem(
                    iconName: "person",
                    title: "利用者管理",
                    subtitle: "\(classGroupCount)組・\(userCount)人登録済み",
                    action: onSelectUser
                )
                .background(
                    highlightUserManagement ? Color.orange.opacity(0.16) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    if highlightUserManagement {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.orange, lineWidth: 2)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityHint(highlightUserManagement ? "次の手順。ここから組と利用者を登録します" : "")

                SettingsMenuItem(
                    iconName: "book",
                    title: "図書管理",
                    subtitle: "\(bookCount)冊登録済み",
                    action: onSelectBook
                )
                .background(
                    highlightBookManagement ? Color.orange.opacity(0.16) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    if highlightBookManagement {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.orange, lineWidth: 2)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityHint(highlightBookManagement ? "次の手順。ここから図書を登録します" : "")

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
                        iconName: "camera.viewfinder",
                        title: "表紙検索の準備",
                        subtitle: coverPreparationStatus,
                        action: onSelectCoverPreparation
                    )

                    SettingsMenuItem(
                        iconName: "person.2.badge.plus",
                        title: "全園児に保護者を作成",
                        subtitle: "現在登録中の園児すべてに対して保護者を自動作成",
                        action: onCreateGuardiansForAllChildren,
                        showChevron: false
                    )

                    SettingsMenuItem(
                        iconName: "books.vertical",
                        title: "図書一括登録",
                        subtitle: "CSVファイルから複数の図書を一括登録",
                        action: onSelectBookBulkRegistration,
                        showChevron: false
                    )

                    SettingsMenuItem(
                        iconName: "graduationcap",
                        title: "進級処理",
                        subtitle: "年度変更時に園児を次の年齢区分に進級（5歳児は卒業として削除）",
                        action: onPromoteToNextYear,
                        showChevron: false
                    )
                }

                Divider()
                    .padding(.vertical, 8)

                // サポートセクション
                VStack(alignment: .leading, spacing: 8) {
                    Text("サポート")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    SettingsMenuItem(
                        iconName: "envelope",
                        title: "不具合・ご要望を報告",
                        subtitle: "報告フォームを開きます",
                        action: onSelectFeedback,
                        showChevron: false
                    )

                    SettingsMenuItem(
                        iconName: "qrcode",
                        title: "保護者向け不具合・ご要望フォームのQRコード",
                        subtitle: "掲示・印刷して保護者に案内できます",
                        action: onSelectParentFeedbackQRCode,
                        showChevron: false
                    )

                    SettingsMenuItem(
                        iconName: "doc.text",
                        title: "ライセンス情報",
                        subtitle: "使用ライブラリと表紙検索モデルのライセンスを確認",
                        action: onSelectLicenses
                    )

                    SettingsMenuItem(
                        iconName: "hand.raised",
                        title: "プライバシーとデータ送信",
                        subtitle: "説明を読む・任意の送信を選ぶ・同意を取り消す",
                        action: onSelectPrivacy
                    )
                }

                Divider()
                    .padding(.vertical, 8)

                // データ引き継ぎセクション
                VStack(alignment: .leading, spacing: 8) {
                    Text("データ引き継ぎ")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    SettingsMenuItem(
                        iconName: "square.and.arrow.up",
                        title: "バックアップを書き出す",
                        subtitle: "図書・利用者・貸出記録などをファイルに保存",
                        action: onSelectBackupExport,
                        showChevron: false
                    )

                    SettingsMenuItem(
                        iconName: "square.and.arrow.down",
                        title: "バックアップから復元する",
                        subtitle: "書き出したファイルから全データを復元（既存データは置き換わります）",
                        action: onSelectBackupImport,
                        showChevron: false
                    )
                }

                Divider()
                    .padding(.vertical, 8)

                SettingsMenuItem(
                    iconName: "trash.circle",
                    title: "端末初期化",
                    subtitle: "利用者・図書・貸出記録のデータを削除",
                    action: onSelectDeviceReset,
                    style: .destructive,
                    showChevron: false
                )
            }
            .padding()
        }
        .background(AppColor.settingsBackground)
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
            case .destructive: return AppColor.destructive
            }
        }

        var titleColor: Color {
            switch self {
            case .normal: return .primary
            case .destructive: return AppColor.destructive
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
                        .foregroundStyle(.primary.opacity(0.7))
                }
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(AppColor.cardSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(AppColor.settingsCardBorder, lineWidth: 1)
                    .allowsHitTesting(false)
            }
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
            onPromoteToNextYear: {},
            onSelectDeviceReset: {},
            onSelectFeedback: {},
            onSelectParentFeedbackQRCode: {},
            onSelectBackupExport: {},
            onSelectBackupImport: {},
            onSelectPrivacy: {},
            onSelectLicenses: {}
        )
        .navigationTitle("設定")
    }
}
