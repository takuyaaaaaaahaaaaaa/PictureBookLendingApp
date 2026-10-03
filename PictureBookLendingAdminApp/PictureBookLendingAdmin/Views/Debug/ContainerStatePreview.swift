#if DEBUG
    import PictureBookLendingDomain
    import PictureBookLendingInfrastructure
    import PictureBookLendingModel
    import SwiftUI
    
    /// 本番ContainerのState寿命を、メモリ内の見本だけで確認する。
    /// 幅は親のframeだけで変え、Containerのidentityとモデルを維持する。
    struct ContainerStatePreview: View {
        @Environment(\.dismiss) private var dismiss
        @State private var fixtures = ContainerPreviewFixtures()
        @State private var width: CGFloat = 375
        @State private var screen = Screen.books
        @State private var borrowClosed = false
        
        private enum Screen: String, CaseIterable, Identifiable {
            case books = "図書"
            case form = "利用者入力"
            case users = "利用者詳細"
            case borrow = "貸出選択"
            case returns = "返却詳細"
            var id: String { rawValue }
        }
        
        var body: some View {
            VStack(spacing: 8) {
                Button("確認を終了") { dismiss() }
                HStack {
                    ForEach([375, 744, 1024], id: \.self) { value in
                        Button("\(value)pt") { width = CGFloat(value) }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("container.width.\(value)")
                    }
                    Picker("画面", selection: $screen) {
                        ForEach(Screen.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Text("メモリ内の見本のみ / 本番Container / Duo実機の代替ではありません")
                    .font(.caption)
                GeometryReader { geometry in
                    let appliedWidth = min(width, geometry.size.width)
                    VStack(spacing: 8) {
                        Text("指定 \(Int(width))pt / 実効 \(Int(appliedWidth))pt")
                            .font(.caption)
                        screenContent
                            .environment(fixtures.books)
                            .environment(fixtures.users)
                            .environment(fixtures.groups)
                            .environment(fixtures.loans)
                            .environment(\.analytics, NoopAnalyticsService())
                            .defaultAppStorage(fixtures.defaults)
                            .frame(width: appliedWidth)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Containerの状態保持")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: screen) { _, _ in borrowClosed = false }
        }
        
        @ViewBuilder
        private var screenContent: some View {
            switch screen {
            case .books:
                BorrowListContainerView(showsSettings: false)
            case .form:
                UserFormContainerView(initialClassGroupId: fixtures.group.id)
            case .users:
                NavigationStack { UserListContainerView() }
            case .borrow:
                if borrowClosed {
                    Button("貸出選択を開き直す（無操作時は通常どおり閉じます）") { borrowClosed = false }
                } else {
                    BorrowSheetContainerView(
                        context: BorrowSheetContext(
                            book: fixtures.availableBook, isAlreadyLent: false),
                        onClose: { borrowClosed = true }, onLendCompleted: { borrowClosed = true })
                }
            case .returns:
                ReturnListContainerView(showsSettings: false)
            }
        }
    }
    
    @MainActor
    private final class ContainerPreviewFixtures {
        let books: BookModel
        let users: UserModel
        let groups: ClassGroupModel
        let loans: LoanModel
        let group: ClassGroup
        let availableBook: Book
        let defaults: UserDefaults
        private let defaultsName: String
        
        init() {
            let factory = MockRepositoryFactory()
            let group = ClassGroup(name: "見本の組", ageGroup: .age(4), year: 2026)
            self.group = group
            try! factory.classGroupRepository.save(group)
            let sampleUsers = (1...12).map { User(name: "見本の利用者 \($0)", classGroupId: group.id) }
            for user in sampleUsers { _ = try! factory.userRepository.save(user) }
            let sampleBooks = (1...60).map {
                Book(
                    title: String(format: "あいうの見本 %02d", $0),
                    managementNumber: String(format: "見本%03d", $0))
            }
            for book in sampleBooks { _ = try! factory.bookRepository.save(book) }
            availableBook = sampleBooks[1]
            _ = try! factory.loanRepository.save(
                Loan(
                    bookId: sampleBooks[0].id, user: sampleUsers[0], loanDate: .now,
                    dueDate: .now.addingTimeInterval(7 * 24 * 60 * 60)))
            books = BookModel(repository: factory.bookRepository)
            users = UserModel(repository: factory.userRepository)
            groups = ClassGroupModel(repository: factory.classGroupRepository)
            loans = LoanModel(
                repository: factory.loanRepository, bookRepository: factory.bookRepository,
                userRepository: factory.userRepository,
                loanSettingsRepository: factory.loanSettingsRepository)
            defaultsName = "ContainerStatePreview.\(UUID().uuidString)"
            defaults = UserDefaults(suiteName: defaultsName)!
        }
        
        deinit { defaults.removePersistentDomain(forName: defaultsName) }
    }
#endif
