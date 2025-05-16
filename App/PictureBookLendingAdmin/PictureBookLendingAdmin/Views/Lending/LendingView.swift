import SwiftUI
import PictureBookLendingCore

/**
 * 貸出・返却管理ビュー
 *
 * 現在の貸出状況を一覧表示し、新規貸出と返却機能を提供します。
 */
struct LendingView: View {
    @Environment(\.lendingModel) private var lendingModel
    
    // ローンの種類によるフィルタ状態
    @State private var filterSelection = 0 // 0: 全て, 1: 貸出中, 2: 返却済み
    
    // 新規貸出登録シート表示状態
    @State private var showingNewLoanSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // フィルタセグメント
                Picker("表示", selection: $filterSelection) {
                    Text("全て").tag(0)
                    Text("貸出中").tag(1)
                    Text("返却済み").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                List {
                    if let lendingModel = lendingModel {
                        let loans = filteredLoans(lendingModel)
                        
                        if loans.isEmpty {
                            ContentUnavailableView("貸出情報がありません", systemImage: "book.closed", description: Text("右上の＋ボタンから新しい貸出を登録してください"))
                        } else {
                            ForEach(loans) { loan in
                                LoanRowView(loan: loan)
                            }
                        }
                    } else {
                        Text("貸出情報を読み込めませんでした")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("貸出・返却管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewLoanSheet = true
                    }) {
                        Label("貸出登録", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewLoanSheet) {
                NewLoanView()
            }
        }
    }
    
    // フィルタリングされた貸出情報
    private func filteredLoans(_ lendingModel: LendingModel) -> [Loan] {
        let allLoans = lendingModel.getAllLoans()
        
        switch filterSelection {
        case 1: // 貸出中
            return allLoans.filter { !$0.isReturned }
        case 2: // 返却済み
            return allLoans.filter { $0.isReturned }
        default: // 全て
            return allLoans
        }
    }
}

/**
 * 貸出情報行ビュー
 *
 * 一覧の各行に表示する貸出情報のレイアウトを定義します。
 */
struct LoanRowView: View {
    @Environment(\.bookModel) private var bookModel
    @Environment(\.userModel) private var userModel
    @Environment(\.lendingModel) private var lendingModel
    
    let loan: Loan
    
    @State private var showingReturnConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
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
                        .foregroundColor(.green)
                } else {
                    // 貸出中の場合
                    Button(action: {
                        showingReturnConfirmation = true
                    }) {
                        Text("返却")
                            .foregroundColor(.blue)
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
                        .foregroundColor(isOverdue ? .red : .primary)
                }
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog("返却処理", isPresented: $showingReturnConfirmation) {
            Button("返却を記録する", role: .destructive) {
                returnBook()
            }
        } message: {
            Text("\(bookTitle) の返却を記録しますか？")
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // 書籍名の取得
    private var bookTitle: String {
        if let bookModel = bookModel, let book = bookModel.findBookById(loan.bookId) {
            return book.title
        }
        return "不明な書籍"
    }
    
    // 利用者名の取得
    private var userName: String {
        if let userModel = userModel, let user = userModel.findUserById(loan.userId) {
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
    
    // 返却処理
    private func returnBook() {
        guard let lendingModel = lendingModel else {
            showError("モデルが利用できません")
            return
        }
        
        do {
            _ = try lendingModel.returnBook(loanId: loan.id)
        } catch {
            showError("返却処理に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // エラー表示
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    LendingView()
}