import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
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
    @State private var isBackupExporterPresented = false
    @State private var isBackupImporterPresented = false
    @State private var isRestoreConfirmationPresented = false
    @State private var backupExportDocument: BackupDocument?
    @State private var pendingRestoreSnapshot: BackupSnapshot?
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            SettingsView(
                classGroupCount: classGroupModel.classGroups.count,
                userCount: userModel.users.count,
                bookCount: bookModel.books.count,
                loanPeriodDays: loanSettingsModel.settings.defaultLoanPeriodDays,
                maxBooksPerUser: loanSettingsModel.settings.maxBooksPerUser,
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
                }
            )
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .user:
                    ClassGroupListContainerView { classGroupId in
                        navigationPath.append(SettingsDestination.userList(classGroupId))
                    }
                case .userList(let classGroupId):
                    UserListContainerView(classGroupId: classGroupId)
                case .book:
                    SettingsBookListContainerView()
                }
            }
            .sheet(isPresented: $isLoanSettingsSheetPresented) {
                NavigationStack {
                    LoanSettingsContainerView()
                }
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
                        .navigationTitle("保護者向けQRコード")
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
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleDeviceReset(_ options: DeviceResetOptions) {
        Task {
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
        do {
            var deletedDetails: [String] = []
            
            // 貸出記録を残したまま利用者や図書を消すと、返却する手段のない貸出が残るため、
            // 借りたままの図書を先に返却しておく（記録ごと消す場合は不要）
            var returnedLoanCount = 0
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
                deletedDetails.append("図書データ(\(bookCount)冊)")
            }
            
            if options.deleteLoanRecords {
                let loanCount = try loanModel.deleteAllLoans()
                deletedDetails.append("貸出記録(\(loanCount)件)")
            }
            
            var message =
                if !deletedDetails.isEmpty {
                    "以下のデータを削除しました:\n\(deletedDetails.joined(separator: "\n"))"
                } else {
                    "削除するデータが選択されていません"
                }
            message = Self.appendingAutoReturnNotice(to: message, count: returnedLoanCount)
            
            alertState = .info(message)
            
        } catch {
            alertState = .error("データ削除に失敗しました", message: "\(error.localizedDescription)")
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
        do {
            let snapshot = try backupModel.createSnapshot()
            backupExportDocument = BackupDocument(snapshot: snapshot)
            isBackupExporterPresented = true
        } catch {
            alertState = .error("バックアップの作成に失敗しました", message: "\(error.localizedDescription)")
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
        guard let snapshot = pendingRestoreSnapshot else { return }
        pendingRestoreSnapshot = nil
        
        do {
            let summary = try backupModel.restore(from: snapshot)
            
            // 各Modelのキャッシュをリポジトリの最新状態に合わせる
            // （復元は全件置き換えのため、削除分も反映される全件再読み込みを使う）
            classGroupModel.refreshClassGroups()
            userModel.refreshUsers()
            bookModel.refreshBooks()
            loanModel.reloadAllLoans()
            loanSettingsModel.reload()
            
            alertState = .info(
                "復元が完了しました",
                message:
                    "組: \(summary.classGroupCount)件 / 利用者: \(summary.userCount)人 / 図書: \(summary.bookCount)冊 / 貸出記録: \(summary.loanCount)件"
            )
        } catch {
            alertState = .error("データの復元に失敗しました", message: "\(error.localizedDescription)")
        }
    }
    
    private enum SettingsDestination: Hashable {
        case user
        case userList(UUID)
        case book
    }
}

#Preview {
    let mockFactory = MockRepositoryFactory()
    
    SettingsContainerView()
        .environment(ClassGroupModel(repository: mockFactory.classGroupRepository))
        .environment(UserModel(repository: mockFactory.userRepository))
        .environment(BookModel(repository: mockFactory.bookRepository))
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
