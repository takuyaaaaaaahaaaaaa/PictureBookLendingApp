import PictureBookLendingDomain
import SwiftUI

/// 新規貸出登録のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct NewLoanView: View {
    let books: [Book]
    let users: [User]
    let selectedBookId: UUID?
    let selectedUserId: UUID?
    let dueDate: Date
    let bookSearchText: Binding<String>
    let userSearchText: Binding<String>
    let dueDateBinding: Binding<Date>
    let isBookLent: (UUID) -> Bool
    let onBookSelect: (UUID) -> Void
    let onUserSelect: (UUID) -> Void
    let onCancel: () -> Void
    let onRegister: () -> Void
    let isValidInput: Bool
    
    public init(
        books: [Book],
        users: [User],
        selectedBookId: UUID?,
        selectedUserId: UUID?,
        dueDate: Date,
        bookSearchText: Binding<String>,
        userSearchText: Binding<String>,
        dueDateBinding: Binding<Date>,
        isBookLent: @escaping (UUID) -> Bool,
        onBookSelect: @escaping (UUID) -> Void,
        onUserSelect: @escaping (UUID) -> Void,
        onCancel: @escaping () -> Void,
        onRegister: @escaping () -> Void,
        isValidInput: Bool
    ) {
        self.books = books
        self.users = users
        self.selectedBookId = selectedBookId
        self.selectedUserId = selectedUserId
        self.dueDate = dueDate
        self.bookSearchText = bookSearchText
        self.userSearchText = userSearchText
        self.dueDateBinding = dueDateBinding
        self.isBookLent = isBookLent
        self.onBookSelect = onBookSelect
        self.onUserSelect = onUserSelect
        self.onCancel = onCancel
        self.onRegister = onRegister
        self.isValidInput = isValidInput
    }
    
    public var body: some View {
        Form {
            Section(header: Text("絵本を選択")) {
                if books.isEmpty {
                    Text("検索条件に一致する絵本はありません")
                        .italic()
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(books) { book in
                        BookSelectionRow(
                            book: book,
                            isSelected: book.id == selectedBookId,
                            isLent: isBookLent(book.id)
                        ) {
                            onBookSelect(book.id)
                        }
                        .disabled(isBookLent(book.id))
                    }
                }
            }
            .searchable(text: bookSearchText, prompt: "絵本を検索")
            
            Section(header: Text("利用者を選択")) {
                if users.isEmpty {
                    Text("検索条件に一致する利用者はいません")
                        .italic()
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(users) { user in
                        UserSelectionRow(
                            user: user,
                            isSelected: user.id == selectedUserId
                        ) {
                            onUserSelect(user.id)
                        }
                    }
                }
            }
            .searchable(text: userSearchText, prompt: "利用者を検索")
            
            Section(header: Text("返却期限")) {
                DatePicker(
                    "返却期限",
                    selection: dueDateBinding,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
        }
    }
}

/// 絵本選択行ビュー
public struct BookSelectionRow: View {
    let book: Book
    let isSelected: Bool
    let isLent: Bool
    let onTap: () -> Void
    
    public init(
        book: Book,
        isSelected: Bool,
        isLent: Bool,
        onTap: @escaping () -> Void
    ) {
        self.book = book
        self.isSelected = isSelected
        self.isLent = isLent
        self.onTap = onTap
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                    .foregroundStyle(isLent ? .secondary : .primary)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isLent {
                Text("貸出中")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.2))
                    )
            } else if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isLent {
                onTap()
            }
        }
        .padding(.vertical, 4)
    }
}

/// 利用者選択行ビュー
public struct UserSelectionRow: View {
    let user: User
    let isSelected: Bool
    let onTap: () -> Void
    
    public init(
        user: User,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) {
        self.user = user
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                
                Text("組情報")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let sampleBooks = [
        Book(title: "はらぺこあおむし", author: "エリック・カール"),
        Book(title: "ぐりとぐら", author: "中川李枝子"),
    ]
    let sampleUsers = [
        User(name: "山田太郎", classGroupId: UUID()),
        User(name: "鈴木花子", classGroupId: UUID()),
    ]
    
    NavigationStack {
        NewLoanView(
            books: sampleBooks,
            users: sampleUsers,
            selectedBookId: nil,
            selectedUserId: nil,
            dueDate: Date(),
            bookSearchText: .constant(""),
            userSearchText: .constant(""),
            dueDateBinding: .constant(Date()),
            isBookLent: { _ in false },
            onBookSelect: { _ in },
            onUserSelect: { _ in },
            onCancel: {},
            onRegister: {},
            isValidInput: false
        )
        .navigationTitle("貸出登録")
    }
}
