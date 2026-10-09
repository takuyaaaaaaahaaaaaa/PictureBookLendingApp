import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import StoreKit
import SwiftUI
import UniformTypeIdentifiers

/// 設定画面のコンテナビュー
/// 管理者用の図書・利用者・組管理機能を提供します
struct SettingsContainerView: View {
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(UserModel.self) private var userModel
    @Environment(BookModel.self) private var bookModel
    @Environment(LoanModel.self) private var loanModel
    @Environment(LoanSettingsModel.self) private var loanSettingsModel
    @Environment(BackupModel.self) private var backupModel
    @Environment(TelemetryPrivacyController.self) private var privacy
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @State private var coverRecognition = CoverRecognitionService.shared
    
    @State private var navigationPath = NavigationPath()
    @State private var isLoanSettingsSheetPresented = false
    @State private var isBookBulkRegistrationSheetPresented = false
    @State private var isDeviceResetDialogPresented = false
    /// 進級処理の確認ダイアログ
    ///
    /// 借りたままの図書の冊数を含むため、確認を開いた時点の内容を控えて表示する
    /// （body評価のたびに全利用者の貸出を数え直さないようにするため）
    @State private var promoteConfirmationState = AlertState()
    @State private var isParentFeedbackQRCodeSheetPresented = false
    @State private var deviceResetOptions = DeviceResetOptions()
    @State private var alertState = AlertState()
    @State private var shouldRequestReviewAfterPromotion = false
    @State private var isDataOperationRunning = false
    @State private var isBackupExporterPresented = false
    @State private var isBackupWithoutPreparationConfirmationPresented = false
    @State private var isBackupImporterPresented = false
    @State private var isRestoreConfirmationPresented = false
    @State private var backupExportDocument: BackupDocument?
    @State private var pendingRestoreSnapshot: BackupSnapshot?
    @State private var isInitialConsentPresented = false
    @State private var shouldCloseAfterConsent = false
    @AppStorage("setupGuideStarted") private var setupStarted = false
    @AppStorage("setupGuideCompleted") private var setupCompleted = false
    @AppStorage("setupGuideWelcomeSeen") private var welcomeSeen = false
    @AppStorage("consentPendingAfterWelcomeSkip") private var consentPendingAfterWelcomeSkip =
        false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            guided {
                SettingsView(
                    classGroupCount: classGroupModel.classGroups.count,
                    userCount: userModel.users.count,
                    bookCount: bookModel.books.count,
                    highlightUserManagement: setupStarted && setupProgress.completedCount == 0,
                    highlightBookManagement: setupStarted && setupProgress.hasUser
                        && !setupProgress.hasBook,
                    loanPeriodDays: loanSettingsModel.settings.defaultLoanPeriodDays,
                    maxBooksPerUser: loanSettingsModel.settings.maxBooksPerUser,
                    coverPreparedCount: coverRecognition.preparedCount,
                    coverPendingCount: coverRecognition.pendingCount,
                    isCoverPreparationRunning: coverRecognition.isPreparing,
                    onRetryCoverPreparation: {
                        Task {
                            await coverRecognition.prepare(books: bookModel.books, isComplete: bookModel.hasLoadedBooks)
                            if let message = coverRecognition.preparationError {
                                alertState = .error("検索準備を完了できませんでした", message: message)
                            }
                        }
                    },
                    onSelectUser: {
                        navigationPath.append(SettingsDestination.user)
                    },
                    onSelectBook: {
                        navigationPath.append(SettingsDestination.book)
                    },
                    onSelectBookBulkRegistration: {
                        isBookBulkRegistrationSheetPresented = true
                    },
                    onSelectLoanSettings: {
                        isLoanSettingsSheetPresented = true
                    },
                    onCreateGuardiansForAllChildren: {
                        handleCreateGuardiansForAllChildren()
                    },
                    onPromoteToNextYear: {
                        promoteConfirmationState = AlertState(
                            isPresented: true,
                            title: "進級処理の確認",
                            message: makePromoteConfirmationMessage()
                        )
                    },
                    onSelectDeviceReset: {
                        isDeviceResetDialogPresented = true
                    },
                    onSelectFeedback: {
                        openURL(FeedbackFormLinks.staff)
                    },
                    onSelectParentFeedbackQRCode: {
                        isParentFeedbackQRCodeSheetPresented = true
                    },
                    onSelectBackupExport: {
                        handleBackupExport()
                    },
                    onSelectBackupImport: {
                        isBackupImporterPresented = true
                    },
                    onSelectPrivacy: {
                        navigationPath.append(SettingsDestination.privacy)
                    },
                    onSelectLicenses: {
                        navigationPath.append(SettingsDestination.licenses)
                    }
                )
            }
            .disabled(isDataOperationRunning)
            .overlay {
                if isDataOperationRunning { ProgressView("データを処理しています").padding().background(.regularMaterial) }
            }
            .interactiveDismissDisabled(isDataOperationRunning)
            .safeAreaInset(edge: .bottom) {
                Text(
                    "バージョン \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-")"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 2) {
                    navigationPath.append(SettingsDestination.debug)
                }
            }
            .navigationTitle("設定")
            .toolbar {
                if !setupStarted && setupProgress.completedCount < 3 {
                    ToolbarItem(placement: .primaryAction) {
                        Button("準備ガイド") { setupStarted = true }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .disabled(isDataOperationRunning)
                }
            }
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .user:
                    guided(showContinue: setupProgress.hasClassGroup) {
                        ClassGroupListContainerView { classGroupId in
                            navigationPath.append(SettingsDestination.userList(classGroupId))
                        }
                    }
                case .userList(let classGroupId):
                    guided(showContinue: setupProgress.hasUser) {
                        UserListContainerView(classGroupId: classGroupId)
                    }
                case .book:
                    guided(showContinue: setupProgress.hasBook) {
                        SettingsBookListContainerView(onBookRegistered: handleBookRegistered)
                    }
                case .privacy:
                    PrivacySettingsContainerView()
                case .licenses:
                    ThirdPartyLicensesView()
                case .debug:
                    DebugSettingsView {
                        setupStarted = false
                        setupCompleted = false
                        welcomeSeen = false
                        consentPendingAfterWelcomeSkip = false
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isLoanSettingsSheetPresented) {
                NavigationStack {
                    LoanSettingsContainerView()
                }
            }
            .alert("調整情報なしでバックアップしますか？", isPresented: $isBackupWithoutPreparationConfirmationPresented) {
                Button("調整情報なしで保存") { isBackupExporterPresented = true }
                Button("キャンセル", role: .cancel) { backupExportDocument = nil }
            } message: {
                Text("表紙検索の調整情報を読み込めませんでした。図書・利用者・貸出記録と登録写真はバックアップしますが、調整情報は含まれません。復元後は表紙検索の再準備や写真の調整が必要です。")
            }
            #if os(macOS)
                .sheet(isPresented: $isBookBulkRegistrationSheetPresented) {
                    NavigationStack {
                        BookBulkAddContainerView()
                    }
                }
            #else
                .fullScreenCover(isPresented: $isBookBulkRegistrationSheetPresented) {
                    BookBulkAddContainerView()
                }
            #endif
            .sheet(isPresented: $isDeviceResetDialogPresented) {
                DeviceResetDialog(
                    isPresented: $isDeviceResetDialogPresented,
                    selectedOptions: $deviceResetOptions,
                    onConfirm: handleDeviceReset
                )
            }
            .sheet(isPresented: $isParentFeedbackQRCodeSheetPresented) {
                NavigationStack {
                    FeedbackQRCodeView(url: FeedbackFormLinks.parent)
                        .navigationTitle("保護者向けフォームのQRコード")
                        #if !os(macOS)
                            .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("閉じる") {
                                    isParentFeedbackQRCodeSheetPresented = false
                                }
                            }
                        }
                }
            }
            .alert(
                promoteConfirmationState.title, isPresented: $promoteConfirmationState.isPresented
            ) {
                Button("実行", role: .destructive) {
                    handlePromoteToNextYear()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text(promoteConfirmationState.message)
            }
            .alert("復元の確認", isPresented: $isRestoreConfirmationPresented) {
                Button("復元", role: .destructive) {
                    handleBackupImportConfirmed()
                }
                Button("キャンセル", role: .cancel) {
                    pendingRestoreSnapshot = nil
                }
            } message: {
                Text("現在の利用者・図書・貸出記録・貸出設定はすべて削除され、バックアップファイルの内容に置き換わります。この操作は元に戻せません。")
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertState.message)
            }
            .onChange(of: alertState.isPresented) { _, isPresented in
                guard !isPresented, shouldRequestReviewAfterPromotion else { return }
                shouldRequestReviewAfterPromotion = false
                requestReview()
            }
            .fileExporter(
                isPresented: $isBackupExporterPresented,
                document: backupExportDocument,
                contentType: .json,
                defaultFilename: "picture-book-lending-backup"
            ) { result in
                handleBackupExportResult(result)
            }
            .fileImporter(
                isPresented: $isBackupImporterPresented,
                allowedContentTypes: [.json]
            ) { result in
                handleBackupImportSelection(result)
            }
            .sheet(
                isPresented: $isInitialConsentPresented,
                onDismiss: {
                    if shouldCloseAfterConsent { dismiss() }
                }
            ) {
                PrivacyConsentView(
                    policyURL: PrivacySettingsContainerView.policyURL,
                    onAllow: { finishConsent(allowed: true) },
                    onDecline: { finishConsent(allowed: false) }
                )
                .alert(
                    "変更を保存できませんでした",
                    isPresented: Binding(
                        get: { privacy.persistenceError != nil },
                        set: { if !$0 { privacy.dismissPersistenceError() } }
                    )
                ) {
                    Button("確認", role: .cancel) { privacy.dismissPersistenceError() }
                } message: {
                    Text(privacy.persistenceError ?? "")
                }
                .presentationSizing(.page)
                .interactiveDismissDisabled()
            }
        }
    }
    
    private func guided<Content: View>(
        showContinue: Bool = true,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            if setupStarted && !setupCompleted
                && (!setupProgress.isComplete || privacy.needsInitialConsent)
            {
                SetupProgressView(
                    progress: setupProgress,
                    onContinue: showContinue ? continueSetup : nil
                )
            }
            content()
        }
    }

    private var setupProgress: SetupProgress {
        SetupProgress(
            hasClassGroup: !classGroupModel.classGroups.isEmpty,
            hasUser: !userModel.users.isEmpty,
            hasBook: !bookModel.books.isEmpty
        )
    }

    private func continueSetup() {
        if !setupProgress.hasClassGroup {
            navigationPath.append(SettingsDestination.user)
        } else if !setupProgress.hasUser {
            if let classGroupId = classGroupModel.classGroups.first?.id {
                navigationPath.append(SettingsDestination.userList(classGroupId))
            }
        } else if !setupProgress.hasBook {
            navigationPath.append(SettingsDestination.book)
        } else {
            isInitialConsentPresented = true
        }
    }

    private func handleBookRegistered() {
        guard
            setupStarted && !setupCompleted && setupProgress.isComplete
                && privacy.needsInitialConsent
        else { return }
        isInitialConsentPresented = true
    }

    private func finishConsent(allowed: Bool) {
        privacy.completeInitialConsent(allowed: allowed)
        guard !privacy.needsInitialConsent else { return }
        shouldCloseAfterConsent = true
        isInitialConsentPresented = false
    }

    // MARK: - Action Handlers
    
    private func handleDeviceReset(_ options: DeviceResetOptions) {
        guard !isDataOperationRunning else { return }
        isDataOperationRunning = true
        Task { @MainActor in
            defer { isDataOperationRunning = false }
            await performDeviceReset(options)
        }
    }
    
    private func handleCreateGuardiansForAllChildren() {
        Task {
            await performCreateGuardiansForAllChildren()
        }
    }
    
    private func handlePromoteToNextYear() {
        Task {
            await performPromoteToNextYear()
        }
    }
    
    private func performCreateGuardiansForAllChildren() async {
        do {
            // 園児のみを取得
            let children = userModel.users.filter { $0.userType == .child }
            if children.isEmpty {
                alertState = .error("保護者作成に失敗しました", message: "登録されている園児がいません")
                return
            }
            
            var createdGuardiansCount = 0
            
            // 各園児に対して保護者を作成
            for child in children {
                // 既に保護者がいるかチェック
                let hasExistingGuardian = userModel.users.contains { user in
                    if case .guardian(let relatedChildId) = user.userType {
                        return relatedChildId == child.id
                    }
                    return false
                }
                
                // 保護者がいない場合のみ作成
                if !hasExistingGuardian {
                    let guardian = User(
                        name: "\(child.name)の保護者",
                        classGroupId: child.classGroupId,
                        userType: .guardian(relatedChildId: child.id)
                    )
                    
                    _ = try userModel.registerUser(guardian)
                    createdGuardiansCount += 1
                }
            }
            
            let message =
                if createdGuardiansCount > 0 {
                    "\(createdGuardiansCount)人の保護者を作成しました"
                } else {
                    "すべての園児に既に保護者が登録されています"
                }
            
            alertState = .info(message)
        } catch {
            alertState = .error("保護者作成に失敗しました", message: "\(error.localizedDescription)")
        }
    }
    
    private func performDeviceReset(_ options: DeviceResetOptions) async {
        var deletedDetails: [String] = []
        var failures: [String] = []
        var returnedLoanCount = 0
        do {
            // Preserve the ability to return loans before deleting their books/users.
            if (options.deleteUsers || options.deleteBooks) && !options.deleteLoanRecords {
                returnedLoanCount = try loanModel.returnLoans(loanModel.activeLoans)
            }
            if options.deleteUsers {
                let userCount = try userModel.deleteAllUsers()
                let classGroupCount = try classGroupModel.deleteAllClassGroups()
                deletedDetails.append("利用者データ(\(userCount)人)・クラス(\(classGroupCount)組)")
            }
            if options.deleteBooks {
                let bookCount = try bookModel.deleteAllBooks()
                deletedDetails.append("図書データ(\(bookCount)冊)・登録写真")
            }
            if options.deleteLoanRecords {
                let loanCount = try loanModel.deleteAllLoans()
                deletedDetails.append("貸出記録(\(loanCount)件)")
            }
        } catch { failures.append(error.localizedDescription) }
        // Prune once, even when record/photo deletion only partly succeeded.
        if options.deleteBooks {
            do {
                try await coverRecognition.removeDeletedBooks(books: bookModel.books, isComplete: bookModel.hasLoadedBooks)
                deletedDetails.append("表紙検索データの整理")
            } catch { failures.append(error.localizedDescription) }
        }
        if failures.isEmpty {
            let message = deletedDetails.isEmpty ? "削除するデータが選択されていません"
                : "以下のデータを削除しました:\n\(deletedDetails.joined(separator: "\n"))"
            alertState = .info(Self.appendingAutoReturnNotice(to: message, count: returnedLoanCount))
        } else {
            var message = failures.joined(separator: "\n")
            if !deletedDetails.isEmpty { message += "\n実施済み:\n" + deletedDetails.joined(separator: "\n") }
            alertState = .error("データ削除が完了していません",
                message: Self.appendingAutoReturnNotice(to: message, count: returnedLoanCount))
        }
    }

    /// 進級対応
    private func performPromoteToNextYear() async {
        do {
            // クラス進級処理を実行し、削除されたクラスを取得
            let deletedClassGroups = try classGroupModel.promoteToNextYear()
            var graduationTextArray: [String] = []
            
            var returnedLoanCount = 0
            
            // 削除されたクラスに所属していたユーザーも削除し、卒業メッセージを作成
            for deletedClassGroup in deletedClassGroups {
                // 該当クラスのユーザーを取得（削除前に園児数をカウント）
                let usersInClass = userModel.users.filter { user in
                    user.classGroupId == deletedClassGroup.id
                }
                
                // 借りたままの図書を先に返却する
                // （先に利用者を削除すると、返却する手段のない貸出だけが残ってしまう）
                returnedLoanCount += try loanModel.returnLoans(
                    usersInClass.flatMap { loanModel.getUserActiveLoans(userId: $0.id) })
                
                // ユーザー削除
                _ = try userModel.deleteUsersInClassGroup(deletedClassGroup.id)
                
                // 卒業メッセージを作成（園児がいる場合のみ）
                let childrenCount = usersInClass.filter { $0.userType == .child }.count
                if childrenCount > 0 {
                    graduationTextArray.append(
                        "\(deletedClassGroup.year)年度の\(deletedClassGroup.name)組 \(childrenCount)人")
                }
            }
            // 卒業メッセージ
            var graduationMessage = {
                guard !graduationTextArray.isEmpty else { return "" }
                graduationTextArray.append("が卒業しました🌸")
                return graduationTextArray.joined(separator: "\n")
            }()
            graduationMessage = Self.appendingAutoReturnNotice(
                to: graduationMessage, count: returnedLoanCount)
            
            shouldRequestReviewAfterPromotion = true
            alertState = .info("進級処理が完了しました。", message: graduationMessage)
            
        } catch {
            alertState = .error("進級処理に失敗しました", message: "\(error.localizedDescription)")
        }
    }
    
    /// 進級処理の確認文を組み立てる
    ///
    /// 卒業でいなくなる利用者が借りたままの図書は、進級と同時に自動返却される。
    /// 実物の図書が園に戻っていなくても記録上は返却済みになるため、
    /// 実行前に冊数を知らせて「先に返してもらってから進級する」判断ができるようにする
    private func makePromoteConfirmationMessage() -> String {
        var lines = ["すべてのクラスを次の年齢区分に進級させ、年度を更新します。5歳児クラスは削除されます。この操作は元に戻せません。"]
        
        let graduatingLoanCount = graduatingActiveLoans().count
        if graduatingLoanCount > 0 {
            lines.append("")
            lines.append("卒業する利用者が借りたままの図書が\(graduatingLoanCount)冊あります。削除と同時に自動的に返却されます。")
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// 卒業する組に所属する利用者が借りたままの貸出
    private func graduatingActiveLoans() -> [Loan] {
        let graduatingClassGroupIds = Set(classGroupModel.graduatingClassGroups().map(\.id))
        return
            userModel.users
            .filter { graduatingClassGroupIds.contains($0.classGroupId) }
            .flatMap { loanModel.getUserActiveLoans(userId: $0.id) }
    }
    
    /// 完了メッセージに自動返却の結果を書き添える
    ///
    /// - Parameters:
    ///   - message: 元のメッセージ
    ///   - count: 自動返却した冊数（0なら何も足さない）
    /// - Returns: 自動返却の案内を足したメッセージ
    private static func appendingAutoReturnNotice(to message: String, count: Int) -> String {
        guard count > 0 else { return message }
        
        let separator = message.isEmpty ? "" : "\n\n"
        return message + "\(separator)借りたままだった図書\(count)冊は返却済みにしました。"
    }
    
    private func handleBackupExport() {
        guard !isDataOperationRunning else { return }
        isDataOperationRunning = true
        Task { @MainActor in
            defer { isDataOperationRunning = false }
            do {
                var snapshot = try backupModel.createSnapshot()
                snapshot.coverSearchPreparation = try? await coverRecognition.exportPreparation(
                    books: snapshot.books, bookImages: snapshot.bookImages)
                backupExportDocument = BackupDocument(snapshot: snapshot)
                if snapshot.coverSearchPreparation == nil {
                    // Never silently discard crop choices when creating a library backup.
                    isBackupWithoutPreparationConfirmationPresented = true
                } else {
                    isBackupExporterPresented = true
                }
            } catch {
                alertState = .error("バックアップの作成に失敗しました", message: "\(error.localizedDescription)")
            }
        }
    }
    
    private func handleBackupExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            alertState = .info("バックアップの書き出しが完了しました")
        case .failure(let error):
            alertState = .error("バックアップの書き出しに失敗しました", message: "\(error.localizedDescription)")
        }
        backupExportDocument = nil
    }
    
    private func handleBackupImportSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let snapshot = try loadBackupSnapshot(from: url)
                pendingRestoreSnapshot = snapshot
                isRestoreConfirmationPresented = true
            } catch {
                alertState = .error(
                    "バックアップファイルの読み込みに失敗しました", message: "\(error.localizedDescription)")
            }
        case .failure(let error):
            alertState = .error("バックアップファイルの選択に失敗しました", message: "\(error.localizedDescription)")
        }
    }
    
    private func loadBackupSnapshot(from url: URL) throws -> BackupSnapshot {
        guard url.startAccessingSecurityScopedResource() else {
            throw CocoaError(.fileReadNoPermission)
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let data = try Data(contentsOf: url)
        return try BackupDocument.decoder.decode(BackupSnapshot.self, from: data)
    }
    
    private func handleBackupImportConfirmed() {
        guard !isDataOperationRunning, let snapshot = pendingRestoreSnapshot else { return }
        pendingRestoreSnapshot = nil
        isDataOperationRunning = true
        Task { @MainActor in
            defer { isDataOperationRunning = false }
            do {
                // Reject malformed preparation before replacing any library records.
                try await coverRecognition.validatePreparation(snapshot.coverSearchPreparation)
                let summary = try backupModel.restore(from: snapshot)
                classGroupModel.refreshClassGroups()
                userModel.refreshUsers()
                bookModel.refreshBooks()
                loanModel.reloadAllLoans()
                loanSettingsModel.reload()
                do {
                    try await coverRecognition.restorePreparation(snapshot.coverSearchPreparation,
                        books: bookModel.books, isComplete: bookModel.hasLoadedBooks)
                } catch {
                    alertState = .error("図書データは復元しました", message:
                        "表紙の調整情報を復元できませんでした。\(error.localizedDescription)\nバックアップファイルを残して再試行してください。")
                    return
                }
                let legacyNotice = snapshot.coverSearchPreparation == nil
                    ? "\nこのバックアップには表紙の調整情報が含まれません。必要な本は写真を調整してください。" : ""
                alertState = .info("復元が完了しました", message:
                    "組: \(summary.classGroupCount)件 / 利用者: \(summary.userCount)人 / 図書: \(summary.bookCount)冊 / 貸出記録: \(summary.loanCount)件" + legacyNotice)
            } catch {
                alertState = .error("データの復元に失敗しました", message: "\(error.localizedDescription)")
            }
        }
    }
    
    private enum SettingsDestination: Hashable {
        case user
        case userList(UUID)
        case book
        case privacy
        case licenses
        case debug
    }
}

private struct DebugSettingsView: View {
    let onReplayWelcome: () -> Void
    @State private var isAutoFillTipReplayed = false

    var body: some View {
        Form {
            Section {
                Button("自動入力のTipを再表示") {
                    BookFormTipDebug.replayAutoFillTip()
                    isAutoFillTipReplayed = true
                }
                Button("初回の準備案内を再表示", action: onReplayWelcome)
            } header: {
                Text("案内の再表示")
            } footer: {
                Text("準備案内は設定を閉じた後に表示されます。登録済みの図書・利用者は削除しません。")
            }

            if isAutoFillTipReplayed {
                Section {
                    Text("図書の登録画面を開くと自動入力のTipが再表示されます。")
                }
            }
        }
        .navigationTitle("デバッグ")
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    
    SettingsContainerView()
        .environment(ClassGroupModel(repository: mockFactory.classGroupRepository))
        .environment(UserModel(repository: mockFactory.userRepository))
        .environment(BookModel(repository: mockFactory.bookRepository, imageStorageRepository: mockFactory.imageStorageRepository))
        .environment(
            LoanModel(
                repository: mockFactory.loanRepository,
                bookRepository: mockFactory.bookRepository,
                userRepository: mockFactory.userRepository,
                loanSettingsRepository: mockFactory.loanSettingsRepository
            )
        )
        .environment(LoanSettingsModel(repository: mockFactory.loanSettingsRepository))
        .environment(
            BackupModel(
                bookRepository: mockFactory.bookRepository,
                userRepository: mockFactory.userRepository,
                classGroupRepository: mockFactory.classGroupRepository,
                loanRepository: mockFactory.loanRepository,
                loanSettingsRepository: mockFactory.loanSettingsRepository,
                imageStorageRepository: mockFactory.imageStorageRepository
            ))
}
