import PictureBookLendingDomain
import SwiftUI

/// 絵本詳細のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct BookDetailView: View {
    @Binding var bookTitle: String
    @Binding var bookAuthor: String
    let bookId: UUID
    let isCurrentlyLent: Bool
    let onEdit: () -> Void
    
    public init(
        bookTitle: Binding<String>,
        bookAuthor: Binding<String>,
        bookId: UUID,
        isCurrentlyLent: Bool,
        onEdit: @escaping () -> Void
    ) {
        self._bookTitle = bookTitle
        self._bookAuthor = bookAuthor
        self.bookId = bookId
        self.isCurrentlyLent = isCurrentlyLent
        self.onEdit = onEdit
    }
    
    public var body: some View {
        List {
            Section("基本情報") {
                EditableDetailRow(label: "タイトル", value: $bookTitle)
                EditableDetailRow(label: "著者", value: $bookAuthor)
                DetailRow(label: "管理ID", value: bookId.uuidString)
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
    @Previewable @State var bookTitle = "はらぺこあおむし"
    @Previewable @State var bookAuthor = "エリック・カール"
    let sampleBookId = UUID()
    
    NavigationStack {
        BookDetailView(
            bookTitle: $bookTitle,
            bookAuthor: $bookAuthor,
            bookId: sampleBookId,
            isCurrentlyLent: false,
            onEdit: {}
        )
        .navigationTitle(bookTitle)
    }
}
