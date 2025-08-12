import PictureBookLendingDomain
import SwiftUI
import Kingfisher

/// 絵本詳細のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct BookDetailView<ActionButton: View>: View {
    @Binding var book: Book
    let isCurrentlyLent: Bool
    let onEdit: () -> Void
    let actionButton: () -> ActionButton
    
    public init(
        book: Binding<Book>,
        isCurrentlyLent: Bool,
        onEdit: @escaping () -> Void,
        @ViewBuilder actionButton: @escaping () -> ActionButton
    ) {
        self._book = book
        self.isCurrentlyLent = isCurrentlyLent
        self.onEdit = onEdit
        self.actionButton = actionButton
    }
    
    public var body: some View {
        List {
            Section("サムネイル") {
                HStack {
                    Spacer()
                    
                    KFImage(URL(string: book.thumbnail ?? book.smallThumbnail ?? ""))
                        .placeholder {
                            Image(systemName: "book.closed")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 48))
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 160)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            Section("基本情報") {
                EditableDetailRow(label: "タイトル", value: $book.title)
                EditableDetailRow(label: "著者", value: $book.author)
                DetailRow(label: "管理ID", value: book.id.uuidString)
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
    @Previewable @State var sampleBook = Book(
        title: "はらぺこあおむし",
        author: "エリック・カール",
        smallThumbnail: "https://example.com/small-thumbnail.jpg",
        thumbnail: "https://example.com/thumbnail.jpg"
    )
    
    NavigationStack {
        BookDetailView(
            book: $sampleBook,
            isCurrentlyLent: false,
            onEdit: {}
        ) {
            Button("貸出") {}
                .buttonStyle(.bordered)
        }
        .navigationTitle(sampleBook.title)
    }
}
