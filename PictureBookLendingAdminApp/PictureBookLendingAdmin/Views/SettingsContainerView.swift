import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import PictureBookLendingModel
import PictureBookLendingUI
import SwiftUI

/// 設定画面のコンテナビュー
/// 管理者用の絵本・利用者・組管理機能を提供します
struct SettingsContainerView: View {
    @Environment(ClassGroupModel.self) private var classGroupModel
    @Environment(UserModel.self) private var userModel
    @Environment(BookModel.self) private var bookModel
    @Environment(LoanModel.self) private var loanModel
    @Environment(LoanSettingsModel.self) private var loanSettingsModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var navigationPath = NavigationPath()
    @State private var isLoanSettingsSheetPresented = false
    @State private var isBookBulkRegistrationSheetPresented = false
    @State private var isDeviceResetDialogPresented = false
    @State private var isPromoteConfirmationPresented = false
    @State private var deviceResetOptions = DeviceResetOptions()
    @State private var alertState = AlertState()
    
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
                    isPromoteConfirmationPresented = true
                },
                onSelectDeviceReset: {
                    isDeviceResetDialogPresented = true
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
            .alert("進級処理の確認", isPresented: $isPromoteConfirmationPresented) {
                Button("実行", role: .destructive) {
                    handlePromoteToNextYear()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("すべてのクラスを次の年齢区分に進級させ、年度を更新します。5歳児クラスは削除されます。この操作は元に戻せません。")
            }
            .alert(alertState.title, isPresented: $alertState.isPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertState.message)
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
                alertState = .error("登録されている園児がいません")
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
            alertState = .error("保護者作成中にエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    private func performDeviceReset(_ options: DeviceResetOptions) async {
        do {
            var deletedDetails: [String] = []
            
            if options.deleteUsers {
                let userCount = try userModel.deleteAllUsers()
                let classGroupCount = try classGroupModel.deleteAllClassGroups()
                deletedDetails.append("利用者データ(\(userCount)人)・クラス(\(classGroupCount)組)")
            }
            
            if options.deleteBooks {
                let bookCount = try bookModel.deleteAllBooks()
                deletedDetails.append("絵本データ(\(bookCount)冊)")
            }
            
            if options.deleteLoanRecords {
                let loanCount = try loanModel.deleteAllLoans()
                deletedDetails.append("貸出記録(\(loanCount)件)")
            }
            
            let message =
                if !deletedDetails.isEmpty {
                    "以下のデータを削除しました:\n\(deletedDetails.joined(separator: "\n"))"
                } else {
                    "削除するデータが選択されていません"
                }
            
            alertState = .info(message)
            
        } catch {
            alertState = .error("削除中にエラーが発生しました: \(error.localizedDescription)")
        }
    }
    
    /// 進級対応
    private func performPromoteToNextYear() async {
        do {
            // クラス進級処理を実行し、削除されたクラスを取得
            let deletedClassGroups = try classGroupModel.promoteToNextYear()
            var graduationTextArray: [String] = []
            
            // 削除されたクラスに所属していたユーザーも削除し、卒業メッセージを作成
            for deletedClassGroup in deletedClassGroups {
                // 該当クラスのユーザーを取得（削除前に園児数をカウント）
                let usersInClass = userModel.users.filter { user in
                    user.classGroupId == deletedClassGroup.id
                }
                
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
            let graduationMessage = {
                guard !graduationTextArray.isEmpty else { return "" }
                graduationTextArray.append("が卒業しました🌸")
                return graduationTextArray.joined(separator: "\n")
            }()
            
            alertState = .info("進級処理が完了しました。", message: graduationMessage)
            
        } catch {
            alertState = .error("進級処理中にエラーが発生しました: \(error.localizedDescription)")
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
}
