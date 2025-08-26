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
    
    private func performCreateGuardiansForAllChildren() async {
        do {
            // 園児のみを取得
            let children = userModel.users.filter { $0.userType == .child }
            if children.isEmpty {
                alertState = .info("登録されている園児がいません")
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
