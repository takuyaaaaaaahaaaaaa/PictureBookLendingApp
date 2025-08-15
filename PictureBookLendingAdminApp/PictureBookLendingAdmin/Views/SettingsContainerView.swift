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
    @Environment(LoanSettingsModel.self) private var loanSettingsModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var navigationPath = NavigationPath()
    @State private var isLoanSettingsSheetPresented = false
    @State private var isAddBookSheetPresented = false
    @State private var isBulkAddSheetPresented = false
    
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
                onSelectAddBook: {
                    isAddBookSheetPresented = true
                },
                onSelectBulkAdd: {
                    isBulkAddSheetPresented = true
                },
                onSelectLoanSettings: {
                    isLoanSettingsSheetPresented = true
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
                case .book:
                    SettingsBookListContainerView()
                case .userList(let classGroupId):
                    UserListContainerView(classGroupId: classGroupId)
                }
            }
            .sheet(isPresented: $isLoanSettingsSheetPresented) {
                NavigationStack {
                    LoanSettingsContainerView()
                }
            }
            #if os(macOS)
                .sheet(isPresented: $isAddBookSheetPresented) {
                    BookFormContainerView(mode: .add)
                }
            #else
                .fullScreenCover(isPresented: $isAddBookSheetPresented) {
                    BookFormContainerView(mode: .add)
                }
            #endif
            .sheet(isPresented: $isBulkAddSheetPresented) {
                BookBulkAddContainerView()
            }
        }
    }
    
    private enum SettingsDestination: Hashable {
        case user
        case book
        case userList(UUID)
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
