import PictureBookLendingDomain
import SwiftUI

/// 貸出・返却管理のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、alert、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct LendingView: View {
    let loans: [Loan]
    let filterSelection: Binding<Int>
    let onReturn: (UUID) -> Void
    let getBookTitle: (UUID) -> String
    let getUserName: (UUID) -> String
    
    public init(
        loans: [Loan],
        filterSelection: Binding<Int>,
        onReturn: @escaping (UUID) -> Void,
        getBookTitle: @escaping (UUID) -> String,
        getUserName: @escaping (UUID) -> String
    ) {
        self.loans = loans
        self.filterSelection = filterSelection
        self.onReturn = onReturn
        self.getBookTitle = getBookTitle
        self.getUserName = getUserName
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
                            bookTitle: getBookTitle(loan.bookId),
                            userName: getUserName(loan.userId),
                            onReturn: onReturn
                        )
                    }
                }
            }
        }
    }
}

/// 貸出情報行ビュー
///
/// 一覧の各行に表示する貸出情報のレイアウトを定義します。
public struct LoanRowView: View {
    let loan: Loan
    let bookTitle: String
    let userName: String
    let onReturn: (UUID) -> Void
    
    @State private var isReturnConfirmationPresented = false
    @State private var isErrorAlertPresented = false
    @State private var errorMessage = ""
    
    public init(
        loan: Loan,
        bookTitle: String,
        userName: String,
        onReturn: @escaping (UUID) -> Void
    ) {
        self.loan = loan
        self.bookTitle = bookTitle
        self.userName = userName
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
                Text("貸出日: \(loan.loanDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                
                if loan.isReturned, let returnedDate = loan.returnedDate {
                    Text("返却日: \(returnedDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                } else {
                    Text("返却期限: \(loan.dueDate.formatted(date: .abbreviated, time: .omitted))")
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
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // 返却期限切れかどうかのチェック
    private var isOverdue: Bool {
        !loan.isReturned && Date() > loan.dueDate
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
    
    NavigationStack {
        LendingView(
            loans: [loan1],
            filterSelection: .constant(0),
            onReturn: { _ in },
            getBookTitle: { _ in "サンプル本" },
            getUserName: { _ in "山田太郎" }
        )
        .navigationTitle("貸出・返却管理")
    }
}
