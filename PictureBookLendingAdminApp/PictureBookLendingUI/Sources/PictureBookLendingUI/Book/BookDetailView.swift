import PictureBookLendingDomain
import SwiftUI

/// 絵本詳細のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct BookDetailView: View {
    let book: Book
    let isCurrentlyLent: Bool
    let onEdit: () -> Void
    
    public init(
        book: Book,
        isCurrentlyLent: Bool,
        onEdit: @escaping () -> Void
    ) {
        self.book = book
        self.isCurrentlyLent = isCurrentlyLent
        self.onEdit = onEdit
    }
    
    public var body: some View {
        List {
            Section("基本情報") {
                DetailRow(label: "タイトル", value: book.title)
                DetailRow(label: "著者", value: book.author)
                DetailRow(label: "管理ID", value: book.id.uuidString)
            }
            
            Section("貸出状況") {
                HStack {
                    Image(
                        systemName: isCurrentlyLent
                            ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
                    )
                    .foregroundStyle(isCurrentlyLent ? .orange : .green)
                    
                    Text(isCurrentlyLent ? "現在貸出中" : "貸出可能")
                        .foregroundStyle(isCurrentlyLent ? .orange : .green)
                }
            }
            
            Section("貸出履歴") {
                Text("貸出履歴は別画面で確認できます")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    let sampleBook = Book(title: "はらぺこあおむし", author: "エリック・カール")
    
    NavigationStack {
        BookDetailView(
            book: sampleBook,
            isCurrentlyLent: false,
            onEdit: {}
        )
        .navigationTitle(sampleBook.title)
    }
}
