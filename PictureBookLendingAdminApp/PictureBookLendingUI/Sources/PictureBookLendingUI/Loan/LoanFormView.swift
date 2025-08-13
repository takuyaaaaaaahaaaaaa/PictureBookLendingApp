import PictureBookLendingDomain
import SwiftUI

/// 貸出フォームのPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct LoanFormView: View {
    let book: Book
    let classGroups: [ClassGroup]
    let users: [User]
    @Binding var selectedClassGroup: ClassGroup?
    @Binding var selectedUser: User?
    let isValidInput: Bool
    
    public init(
        book: Book,
        classGroups: [ClassGroup],
        users: [User],
        selectedClassGroup: Binding<ClassGroup?>,
        selectedUser: Binding<User?>,
        isValidInput: Bool
    ) {
        self.book = book
        self.classGroups = classGroups
        self.users = users
        self._selectedClassGroup = selectedClassGroup
        self._selectedUser = selectedUser
        self.isValidInput = isValidInput
    }
    
    public var body: some View {
        Form {
            Section(header: Text("絵本")) {
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("組を選択")) {
                Picker("組", selection: $selectedClassGroup) {
                    Text("組を選択してください").tag(nil as ClassGroup?)
                    ForEach(classGroups) { group in
                        Text(group.name).tag(group as ClassGroup?)
                    }
                }
            }
            
            if selectedClassGroup != nil {
                Section(header: Text("利用者を選択")) {
                    if users.isEmpty {
                        Text("この組には利用者が登録されていません")
                            .italic()
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("利用者", selection: $selectedUser) {
                            Text("利用者を選択してください").tag(nil as User?)
                            ForEach(users) { user in
                                Text(user.name).tag(user as User?)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedClassGroup: ClassGroup? = nil
    @Previewable @State var selectedUser: User? = nil
    
    let sampleBook = Book(title: "はらぺこあおむし", author: "エリック・カール")
    
    let sampleClassGroup = ClassGroup(id: UUID(), name: "きく組", ageGroup: 4, year: 2025)
    let sampleClassGroups = [
        sampleClassGroup,
        ClassGroup(id: UUID(), name: "ばら組", ageGroup: 5, year: 2025),
    ]
    
    let sampleUsers = [
        User(name: "山田太郎", classGroupId: sampleClassGroup.id),
        User(name: "鈴木花子", classGroupId: sampleClassGroup.id),
    ]
    
    NavigationStack {
        LoanFormView(
            book: sampleBook,
            classGroups: sampleClassGroups,
            users: sampleUsers,
            selectedClassGroup: $selectedClassGroup,
            selectedUser: $selectedUser,
            isValidInput: selectedClassGroup != nil && selectedUser != nil
        )
        .navigationTitle("貸出登録")
    }
}
