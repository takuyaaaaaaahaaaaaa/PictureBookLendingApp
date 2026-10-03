#if DEBUG
    import PictureBookLendingDomain
    import PictureBookLendingUI
    import SwiftUI
    
    /// 幅だけを変更し、同じNavigationStackとStateを保つ回帰確認用ホスト。
    /// 対角インチはケース名。固定point幅はレイアウトの代理条件で、Duo実機を再現しない。
    struct AdaptiveLayoutPreview: View {
        @State private var width: CGFloat = 375
        @State private var largeText = false
        @State private var screen = PreviewScreen.books
        
        var body: some View {
            VStack(spacing: 8) {
                HStack {
                    Picker("幅", selection: $width) {
                        Text("5.4相当 / 375pt").tag(CGFloat(375))
                        Text("7.6相当 / 744pt").tag(CGFloat(744))
                        Text("12.9相当 / 1024pt").tag(CGFloat(1024))
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("preview.width")
                    Picker("画面", selection: $screen) {
                        ForEach(PreviewScreen.allCases) { value in Text(value.rawValue).tag(value) }
                    }
                    .pickerStyle(.menu)
                    Toggle("AX3", isOn: $largeText).fixedSize()
                }
                Text("見本のみ・保存なし / 幅を変えて検索・表示・スクロールを確認")
                    .font(.caption)
                GeometryReader { geometry in
                    NavigationStack { AdaptiveScreenPreview(screen: screen) }
                        .dynamicTypeSize(largeText ? .accessibility3 : .large)
                        .frame(width: min(width, geometry.size.width), height: geometry.size.height)
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("幅と状態の確認")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    enum PreviewScreen: String, CaseIterable, Identifiable {
        case books = "図書一覧"
        case loans = "貸出一覧"
        case users = "利用者一覧"
        var id: String { rawValue }
    }
    
    struct AdaptiveScreenPreview: View {
        let screen: PreviewScreen
        @State private var selectedGroup: ClassGroup?
        @State private var search = ""
        @State private var children = true
        @State private var guardians = true
        @State private var draftName = ""
        
        private static let group = ClassGroup(name: "見本の組", ageGroup: .age(4), year: 2026)
        private static let users = (1...12).map {
            User(name: "見本の利用者 \($0)", classGroupId: group.id)
        }
        private static let loans = (1...12).map {
            LoanDisplayData(
                id: UUID(), bookId: UUID(), bookTitle: "見本の長い絵本タイトル \($0)",
                userName: "見本の利用者 \($0)", groupName: group.name,
                loanDate: Date(timeIntervalSince1970: 1_790_000_000),
                dueDate: Date(timeIntervalSince1970: 1_791_000_000), isOverdue: $0 == 2)
        }
        
        var body: some View {
            Group {
                switch screen {
                case .books:
                    BookshelfColorPreview(includesWrappedRow: true)
                case .loans:
                    LoanListView(
                        groupedLoans: [Self.group.name: Self.loans],
                        selectedGroupFilter: $selectedGroup, groupFilterOptions: [Self.group]
                    ) { _ in
                        RowActionButton(title: "返す", systemImage: "arrow.uturn.backward", onTap: {})
                    }
                    .navigationTitle("貸出一覧")
                case .users:
                    UserListView(
                        users: Self.users.filter { search.isEmpty || $0.name.contains(search) },
                        searchText: $search, showChildren: $children, showGuardians: $guardians,
                        onDelete: { _ in }
                    ) { user in
                        UserRowView(user: user, classGroupName: Self.group.name)
                    }
                    .navigationTitle("利用者一覧")
                    .navigationDestination(for: User.self) { user in
                        Form {
                            Text(user.name)
                            TextField("入力保持の見本（保存なし）", text: $draftName)
                            Text("幅変更後もこの画面と入力が残ることを確認してください。")
                        }.navigationTitle("入力の見本")
                    }
                }
            }
        }
    }
    
    #Preview("図書・5.4相当・標準", traits: .fixedLayout(width: 375, height: 812)) {
        NavigationStack { AdaptiveScreenPreview(screen: .books) }
    }
    
    #Preview("図書・5.4相当・AX3", traits: .fixedLayout(width: 375, height: 812)) {
        NavigationStack { AdaptiveScreenPreview(screen: .books) }
            .dynamicTypeSize(.accessibility3)
    }
    
    #Preview("図書・7.6相当・標準", traits: .fixedLayout(width: 744, height: 1133)) {
        NavigationStack { AdaptiveScreenPreview(screen: .books) }
    }
    
    #Preview("図書・7.6相当・AX3", traits: .fixedLayout(width: 744, height: 1133)) {
        NavigationStack { AdaptiveScreenPreview(screen: .books) }
            .dynamicTypeSize(.accessibility3)
    }
    
    #Preview("図書・12.9相当・標準", traits: .fixedLayout(width: 1024, height: 1366)) {
        NavigationStack { AdaptiveScreenPreview(screen: .books) }
    }
    
    #Preview("図書・12.9相当・AX3", traits: .fixedLayout(width: 1024, height: 1366)) {
        NavigationStack { AdaptiveScreenPreview(screen: .books) }
            .dynamicTypeSize(.accessibility3)
    }
    
    #Preview("貸出・5.4相当・標準", traits: .fixedLayout(width: 375, height: 812)) {
        NavigationStack { AdaptiveScreenPreview(screen: .loans) }
    }
    
    #Preview("貸出・5.4相当・AX3", traits: .fixedLayout(width: 375, height: 812)) {
        NavigationStack { AdaptiveScreenPreview(screen: .loans) }
            .dynamicTypeSize(.accessibility3)
    }
    
    #Preview("貸出・7.6相当・標準", traits: .fixedLayout(width: 744, height: 1133)) {
        NavigationStack { AdaptiveScreenPreview(screen: .loans) }
    }
    
    #Preview("貸出・7.6相当・AX3", traits: .fixedLayout(width: 744, height: 1133)) {
        NavigationStack { AdaptiveScreenPreview(screen: .loans) }
            .dynamicTypeSize(.accessibility3)
    }
    
    #Preview("貸出・12.9相当・標準", traits: .fixedLayout(width: 1024, height: 1366)) {
        NavigationStack { AdaptiveScreenPreview(screen: .loans) }
    }
    
    #Preview("貸出・12.9相当・AX3", traits: .fixedLayout(width: 1024, height: 1366)) {
        NavigationStack { AdaptiveScreenPreview(screen: .loans) }
            .dynamicTypeSize(.accessibility3)
    }
    
    #Preview("利用者・5.4相当・標準", traits: .fixedLayout(width: 375, height: 812)) {
        NavigationStack { AdaptiveScreenPreview(screen: .users) }
    }
    
    #Preview("利用者・5.4相当・AX3", traits: .fixedLayout(width: 375, height: 812)) {
        NavigationStack { AdaptiveScreenPreview(screen: .users) }
            .dynamicTypeSize(.accessibility3)
    }
    
    #Preview("利用者・7.6相当・標準", traits: .fixedLayout(width: 744, height: 1133)) {
        NavigationStack { AdaptiveScreenPreview(screen: .users) }
    }
    
    #Preview("利用者・7.6相当・AX3", traits: .fixedLayout(width: 744, height: 1133)) {
        NavigationStack { AdaptiveScreenPreview(screen: .users) }
            .dynamicTypeSize(.accessibility3)
    }
    
    #Preview("利用者・12.9相当・標準", traits: .fixedLayout(width: 1024, height: 1366)) {
        NavigationStack { AdaptiveScreenPreview(screen: .users) }
    }
    
    #Preview("利用者・12.9相当・AX3", traits: .fixedLayout(width: 1024, height: 1366)) {
        NavigationStack { AdaptiveScreenPreview(screen: .users) }
            .dynamicTypeSize(.accessibility3)
    }

#endif
