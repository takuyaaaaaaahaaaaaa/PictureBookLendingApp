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
    
    @State private var navigationPath = NavigationPath()
    @State private var isLoanSettingsSheetPresented = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            SettingsView(
                classGroupCount: classGroupModel.classGroups.count,
                userCount: userModel.users.count,
                bookCount: bookModel.books.count,
                loanPeriodDays: loanSettingsModel.settings.defaultLoanPeriodDays,
                onSelectClassGroup: {
                    navigationPath.append(SettingsDestination.classGroup)
                },
                onSelectUser: {
                    navigationPath.append(SettingsDestination.user)
                },
                onSelectBook: {
                    navigationPath.append(SettingsDestination.book)
                },
                onSelectLoanSettings: {
                    isLoanSettingsSheetPresented = true
                }
            )
            .navigationTitle("設定")
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .classGroup:
                    ClassGroupListContainerView()
                case .user:
                    UserListContainerView()
                case .book:
                    BookListContainerView()
                }
            }
            .sheet(isPresented: $isLoanSettingsSheetPresented) {
                NavigationStack {
                    LoanSettingsContainerView()
                }
            }
        }
    }
    
    private enum SettingsDestination: Hashable {
        case classGroup
        case user
        case book
    }
}

#Preview {
    SettingsContainerView()
        .environment(ClassGroupModel(repository: MockClassGroupRepository()))
        .environment(UserModel(repository: MockUserRepository()))
        .environment(BookModel(repository: MockBookRepository()))
        .environment(LoanSettingsModel(repository: MockLoanSettingsRepository()))
}
