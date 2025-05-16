import SwiftUI
import PictureBookLendingCore

/**
 * 絵本詳細表示ビュー
 *
 * 選択された絵本の詳細情報を表示し、編集や貸出履歴の確認などの機能を提供します。
 */
struct BookDetailView: View {
    @Environment(\.bookModel) private var bookModel
    @Environment(\.lendingModel) private var lendingModel
    @Environment(\.dismiss) private var dismiss
    
    // 表示対象の絵本
    let book: Book
    
    // 編集シート表示状態
    @State private var showingEditSheet = false
    
    // 貸出状態確認用フラグ
    @State private var isCurrentlyLent = false
    
    var body: some View {
        List {
            Section("基本情報") {
                DetailRow(label: "タイトル", value: book.title)
                DetailRow(label: "著者", value: book.author)
                DetailRow(label: "管理ID", value: book.id.uuidString)
            }
            
            Section("貸出状況") {
                if isCurrentlyLent {
                    Text("現在貸出中")
                        .foregroundColor(.orange)
                } else {
                    Text("貸出可能")
                        .foregroundColor(.green)
                }
            }
            
            Section("貸出履歴") {
                if let lendingModel = lendingModel, let loans = try? lendingModel.getLoansByBook(bookId: book.id) {
                    if loans.isEmpty {
                        Text("貸出履歴はありません")
                            .italic()
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(loans) { loan in
                            LoanHistoryRow(loan: loan)
                        }
                    }
                } else {
                    Text("貸出履歴の取得に失敗しました")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(book.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            BookFormView(mode: .edit(book))
        }
        .onAppear {
            checkLendingStatus()
        }
    }
    
    // 貸出状態の確認
    private func checkLendingStatus() {
        if let lendingModel = lendingModel {
            isCurrentlyLent = lendingModel.isBookLent(bookId: book.id)
        }
    }
}

/**
 * 詳細表示用の行コンポーネント
 */
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

/**
 * 貸出履歴表示用の行コンポーネント
 */
struct LoanHistoryRow: View {
    @Environment(\.userModel) private var userModel
    
    let loan: Loan
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(userName)
                    .font(.headline)
                Spacer()
                Image(systemName: loan.isReturned ? "checkmark.circle.fill" : "clock")
                    .foregroundColor(loan.isReturned ? .green : .orange)
            }
            
            Text("貸出日: \(formattedDate(loan.loanDate))")
                .font(.caption)
            
            if loan.isReturned, let returnedDate = loan.returnedDate {
                Text("返却日: \(formattedDate(returnedDate))")
                    .font(.caption)
            } else {
                Text("返却期限: \(formattedDate(loan.dueDate))")
                    .font(.caption)
                    .foregroundColor(isOverdue ? .red : .primary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // 利用者名の取得
    private var userName: String {
        if let userModel = userModel, let user = userModel.findUserById(loan.userId) {
            return user.name
        }
        return "不明なユーザー"
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
    NavigationStack {
        BookDetailView(book: Book(title: "はらぺこあおむし", author: "エリック・カール"))
    }
}