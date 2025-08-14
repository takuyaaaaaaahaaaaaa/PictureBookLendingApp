import Kingfisher
import PictureBookLendingDomain
import SwiftUI

/// 絵本検索結果を表示するPresentation View
public struct BookSearchResultsView: View {
    let searchResults: [ScoredBook]
    let onBookSelect: (Book) -> Void
    let onCancel: () -> Void
    
    public init(
        searchResults: [ScoredBook],
        onBookSelect: @escaping (Book) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.searchResults = searchResults
        self.onBookSelect = onBookSelect
        self.onCancel = onCancel
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if searchResults.isEmpty {
                    ContentUnavailableView(
                        "検索結果なし",
                        systemImage: "magnifyingglass",
                        description: Text("該当する絵本が見つかりませんでした")
                    )
                } else {
                    List(searchResults, id: \.book.id) { scoredBook in
                        Button {
                            onBookSelect(scoredBook.book)
                        } label: {
                            BookSearchResultRowView(scoredBook: scoredBook)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("検索結果")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }
            }
        }
    }
}

/// 検索結果の個別行を表示するPresentation View
public struct BookSearchResultRowView: View {
    let scoredBook: ScoredBook
    
    public init(scoredBook: ScoredBook) {
        self.scoredBook = scoredBook
    }
    
    public var body: some View {
        HStack {
            // サムネイル画像
            KFImage(URL(string: scoredBook.book.thumbnail ?? scoredBook.book.smallThumbnail ?? ""))
                .placeholder {
                    Image(systemName: "book.closed")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 80)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scoredBook.book.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(scoredBook.book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let publisher = scoredBook.book.publisher {
                    Text(publisher)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // スコア表示
                HStack {
                    Text("関連度:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(scoredBook.score * 100))%")
                        .font(.caption)
                        .foregroundStyle(scoreColor)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var scoreColor: Color {
        switch scoredBook.score {
        case 0.8...:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    let sampleBooks = [
        ScoredBook(
            book: Book(
                title: "ぐりとぐら",
                author: "なかがわりえこ",
                isbn13: "9784834000825",
                publisher: "福音館書店",
                description: "大きなかすてらを作ったぐりとぐらの楽しいお話",
                thumbnail: "https://example.com/guri-gura.jpg"
            ),
            score: 0.95
        ),
        ScoredBook(
            book: Book(
                title: "はらぺこあおむし",
                author: "エリック・カール",
                isbn13: "9784033280108",
                publisher: "偕成社",
                description: "小さなあおむしの成長物語"
            ),
            score: 0.75
        ),
    ]
    
    BookSearchResultsView(
        searchResults: sampleBooks,
        onBookSelect: { book in
            print("Selected: \(book.title)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
