import SwiftUI
import PictureBookLendingDomain

/**
 * 貸出・返却管理のPresentation View
 *
 * 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
 * 画面制御はContainer Viewに委譲します。
 */
public struct LendingView: View {
    let loans: [Loan]
    let filterSelection: Binding<Int>
    let onReturn: (UUID) -> Void
    let bookModel: any BookModelProtocol
    let userModel: any UserModelProtocol
    let lendingModel: any LendingModelProtocol
    
    public init(
        loans: [Loan],
        filterSelection: Binding<Int>,
        onReturn: @escaping (UUID) -> Void,
        bookModel: any BookModelProtocol,
        userModel: any UserModelProtocol,
        lendingModel: any LendingModelProtocol
    ) {
        self.loans = loans
        self.filterSelection = filterSelection
        self.onReturn = onReturn
        self.bookModel = bookModel
        self.userModel = userModel
        self.lendingModel = lendingModel
    }
    
    public var body: some View {
        VStack {
            // フィルタセグメント
            Picker("表示", selection: filterSelection) {
                Text("全て").tag(0)
                Text("貸出中").tag(1)
                Text("返却済み").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if loans.isEmpty {
                ContentUnavailableView(
                    "貸出情報がありません",
                    systemImage: "book.closed",
                    description: Text("右上の＋ボタンから新しい貸出を登録してください")
                )
            } else {
                List {
                    ForEach(loans) { loan in
                        LoanRowView(
                            loan: loan,
                            bookModel: bookModel,
                            userModel: userModel,
                            lendingModel: lendingModel,
                            onReturn: onReturn
                        )
                    }
                }
            }
        }
    }
}

/**
 * 貸出情報行ビュー
 *
 * 一覧の各行に表示する貸出情報のレイアウトを定義します。
 */
public struct LoanRowView: View {
    let loan: Loan
    let bookModel: any BookModelProtocol
    let userModel: any UserModelProtocol
    let lendingModel: any LendingModelProtocol
    let onReturn: (UUID) -> Void
    
    @State private var isReturnConfirmationPresented = false
    @State private var isErrorAlertPresented = false
    @State private var errorMessage = ""
    
    public init(
        loan: Loan,
        bookModel: any BookModelProtocol,
        userModel: any UserModelProtocol,
        lendingModel: any LendingModelProtocol,
        onReturn: @escaping (UUID) -> Void
    ) {
        self.loan = loan
        self.bookModel = bookModel
        self.userModel = userModel
        self.lendingModel = lendingModel
        self.onReturn = onReturn
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text(bookTitle)
                        .font(.headline)
                    
                    Text(userName)
                        .font(.subheadline)
                }
                
                Spacer()
                
                if loan.isReturned {
                    // 返却済みの場合
                    Label("返却済", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    // 貸出中の場合
                    Button(action: {
                        isReturnConfirmationPresented = true
                    }) {
                        Text("返却")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // 日付情報
            Group {
                Text("貸出日: \(formattedDate(loan.loanDate))")
                    .font(.caption)
                
                if loan.isReturned, let returnedDate = loan.returnedDate {
                    Text("返却日: \(formattedDate(returnedDate))")
                        .font(.caption)
                } else {
                    Text("返却期限: \(formattedDate(loan.dueDate))")
                        .font(.caption)
                        .foregroundStyle(isOverdue ? .red : .primary)
                }
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog("返却処理", isPresented: $isReturnConfirmationPresented) {
            Button("返却を記録する", role: .destructive) {
                onReturn(loan.id)
            }
        } message: {
            Text("\(bookTitle) の返却を記録しますか？")
        }
        .alert("エラー", isPresented: $isErrorAlertPresented) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // 書籍名の取得
    private var bookTitle: String {
        if let book = bookModel.findBookById(loan.bookId) {
            return book.title
        }
        return "不明な書籍"
    }
    
    // 利用者名の取得
    private var userName: String {
        if let user = userModel.findUserById(loan.userId) {
            return user.name
        }
        return "不明な利用者"
    }
    
    // 返却期限切れかどうかのチェック
    private var isOverdue: Bool {
        !loan.isReturned && Date() > loan.dueDate
    }
    
    // 日付のフォーマット
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}


#Preview {
    let loan1 = Loan(
        bookId: UUID(),
        userId: UUID(),
        loanDate: Date(),
        dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
        returnedDate: nil
    )
    
    let mockBookModel = MockBookModel()
    let mockUserModel = MockUserModel()
    let mockLendingModel = MockLendingModel()
    
    NavigationStack {
        LendingView(
            loans: [loan1],
            filterSelection: .constant(0),
            onReturn: { _ in },
            bookModel: mockBookModel,
            userModel: mockUserModel,
            lendingModel: mockLendingModel
        )
        .navigationTitle("貸出・返却管理")
    }
}

// MARK: - Mock Models for Preview

private class MockBookModel: BookModelProtocol {
    func findBookById(_ id: UUID) -> Book? {
        Book(title: "サンプル本", author: "著者名")
    }
}

private class MockUserModel: UserModelProtocol {
    func findUserById(_ id: UUID) -> User? {
        User(name: "山田太郎", group: "1年2組")
    }
}

private class MockLendingModel: LendingModelProtocol {
}