import SwiftUI
import PictureBookLendingCore

@main
public struct UserApp: App {
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            UserContentView()
        }
    }
}

public struct UserContentView: View {
    private let bookBrowsingService = BookBrowsingService()
    private let userLendingService = UserLendingService()
    @State private var books: [Book] = []
    private let userId = UUID()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            List(books, id: \.id) { book in
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
