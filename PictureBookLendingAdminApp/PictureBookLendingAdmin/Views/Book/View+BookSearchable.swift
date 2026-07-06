import PictureBookLendingDomain
import SwiftUI

/// 図書検索用の`.searchable` + `.searchSuggestions`をまとめて適用するView拡張
///
/// 貸出タブ・設定の図書一覧で検索バーとサジェスト表示を共通化する。
/// 候補をタップするとタイトルが検索欄に入り、一覧が絞り込まれる（`.searchCompletion`）。
extension View {
    func bookSearchable(text: Binding<String>, suggestions: [Book]) -> some View {
        #if os(iOS)
            self.searchable(
                text: text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "図書のタイトルまたは著者で検索"
            )
            .searchSuggestions {
                bookSuggestionRows(suggestions)
            }
        #else
            self.searchable(text: text, prompt: "図書のタイトルまたは著者で検索")
                .searchSuggestions {
                    bookSuggestionRows(suggestions)
                }
        #endif
    }
}

/// 検索候補の行表示（タイトル＋著者）
@ViewBuilder
private func bookSuggestionRows(_ suggestions: [Book]) -> some View {
    ForEach(suggestions) { book in
        VStack(alignment: .leading, spacing: 2) {
            Text(book.title)
            if let author = book.author {
                Text(author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .searchCompletion(book.title)
    }
}
