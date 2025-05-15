import SwiftUI

struct UserContentView: View {
    private let bookBrowsingService = BookBrowsingService()
    private let userLendingService = UserLendingService()
    @State private var books: [Book] = []
    private let userId = UUID()
    
    var body: some View {
        NavigationView {
            List(books) { book in
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.headline)
                    Text(book.author)
                        .font(.subheadline)
                }
                .onTapGesture {
                    borrowBook(book)
                }
            }
            .navigationTitle("ユーザーアプリ")
            .onAppear {
                books = bookBrowsingService.searchBooks()
            }
        }
    }
    
    private func borrowBook(_ book: Book) {
        let _ = userLendingService.borrowBook(userId: userId, bookId: book.id)
    }
}

struct UserContentView_Previews: PreviewProvider {
    static var previews: some View {
        UserContentView()
    }
}
