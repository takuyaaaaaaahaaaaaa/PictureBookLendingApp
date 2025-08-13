import Kingfisher
import PictureBookLendingDomain
import SwiftUI

/// 絵本詳細のPresentation View
///
/// 純粋なUI表示のみを担当し、NavigationStack、toolbar、sheet等の
/// 画面制御はContainer Viewに委譲します。
public struct BookDetailView<ActionButton: View>: View {
    /// 表示・編集対象の絵本データ
    @Binding var book: Book
    /// 現在の貸出情報（貸出中の場合のみ存在）
    let currentLoan: Loan?
    /// 貸出履歴一覧
    let loanHistory: [Loan]
    /// 編集ボタンタップ時のアクション
    let onEdit: () -> Void
    /// 貸出・返却などのアクションボタンを生成するクロージャ
    let actionButton: () -> ActionButton
    
    public init(
        book: Binding<Book>,
        currentLoan: Loan? = nil,
        loanHistory: [Loan] = [],
        onEdit: @escaping () -> Void,
        @ViewBuilder actionButton: @escaping () -> ActionButton
    ) {
        self._book = book
        self.currentLoan = currentLoan
        self.loanHistory = loanHistory
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
                    BookStatusView(isCurrentlyLent: currentLoan != nil)
                    
                    Spacer()
                    
                    actionButton()
                }
                
                if let loan = currentLoan {
                    HStack {
                        Text("返却予定日")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(
                            loan.dueDate.formatted(
                                .dateTime.year().month(.abbreviated).day().locale(
                                    Locale(identifier: "ja_JP"))))
                    }
                }
            }
            
            Section("貸出履歴") {
                if loanHistory.isEmpty {
                    Text("まだ貸出履歴がありません")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    ForEach(loanHistory) { loan in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(loan.user.name)
                                    .font(.headline)
                                Spacer()
                                if loan.isReturned {
                                    Label("返却済", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else {
                                    Label("貸出中", systemImage: "clock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                            
                            HStack {
                                Text(
                                    "貸出日: \(loan.loanDate.formatted(.dateTime.year().month(.abbreviated).day().locale(Locale(identifier: "ja_JP"))))"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                if let returnedDate = loan.returnedDate {
                                    Text(
                                        "返却日: \(returnedDate.formatted(.dateTime.year().month(.abbreviated).day().locale(Locale(identifier: "ja_JP"))))"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                } else {
                                    Text(
                                        "返却期限: \(loan.dueDate.formatted(.dateTime.year().month(.abbreviated).day().locale(Locale(identifier: "ja_JP"))))"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(Date() > loan.dueDate ? .red : .secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
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
            currentLoan: nil,
            onEdit: {}
        ) {
            Button("貸出") {}
                .buttonStyle(.bordered)
        }
        .navigationTitle(sampleBook.title)
    }
}
