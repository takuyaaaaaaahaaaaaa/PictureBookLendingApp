import SwiftUI
import PictureBookLendingDomain
import Observation

/**
 * 絵本詳細表示ビュー
 *
 * 選択された絵本の詳細情報を表示し、編集や貸出履歴の確認などの機能を提供します。
 */
struct BookDetailView: View {
    let bookModel: BookModel
    
    // 表示対象の絵本
    let book: Book
    
    // 更新後の絵本情報
    @State private var updatedBook: Book
    
    // 編集シート表示状態
    @State private var showingEditSheet = false
    
    // 貸出状態確認用フラグ
    @State private var isCurrentlyLent = false
    
    init(bookModel: BookModel, book: Book) {
        self.bookModel = bookModel
        self.book = book
        self._updatedBook = State(initialValue: book)
    }
    
    var body: some View {
        List {
            Section("基本情報") {
                DetailRow(label: "タイトル", value: updatedBook.title)
                DetailRow(label: "著者", value: updatedBook.author)
                DetailRow(label: "管理ID", value: updatedBook.id.uuidString)
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
                // Note: This section will be implemented when LendingModel is properly passed
                Text("貸出履歴はこのビューでは表示できません")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(updatedBook.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            BookFormView(
                bookModel: bookModel,
                mode: .edit(updatedBook),
                onSave: { savedBook in
                    updatedBook = savedBook
                    checkLendingStatus()
                }
            )
        }
        .onAppear {
            checkLendingStatus()
        }
    }
    
    // 貸出状態の確認
    private func checkLendingStatus() {
        // Note: This will be implemented when LendingModel is properly passed
        isCurrentlyLent = false
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

#Preview {
    let mockFactory = MockRepositoryFactory()
    let bookModel = BookModel(repository: mockFactory.bookRepository)
    let book = Book(title: "はらぺこあおむし", author: "エリック・カール")
    return NavigationStack {
        BookDetailView(bookModel: bookModel, book: book)
    }
}
