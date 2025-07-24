import PictureBookLendingDomain
import SwiftUI

/// 絵本詳細のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct BookDetailView<ActionButton: View>: View {
    @Binding var bookTitle: String
    @Binding var bookAuthor: String
    let bookId: UUID
    let isCurrentlyLent: Bool
    let onEdit: () -> Void
    let actionButton: () -> ActionButton
    
    public init(
        bookTitle: Binding<String>,
        bookAuthor: Binding<String>,
        bookId: UUID,
        isCurrentlyLent: Bool,
        onEdit: @escaping () -> Void,
        @ViewBuilder actionButton: @escaping () -> ActionButton
    ) {
        self._bookTitle = bookTitle
        self._bookAuthor = bookAuthor
        self.bookId = bookId
        self.isCurrentlyLent = isCurrentlyLent
        self.onEdit = onEdit
        self.actionButton = actionButton
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
                    BookStatusView(isCurrentlyLent: isCurrentlyLent)
                    
                    Spacer()
                    
                    actionButton()
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
        ) {
            Button("貸出") {}
                .buttonStyle(.bordered)
        }
        .navigationTitle(bookTitle)
    }
}
