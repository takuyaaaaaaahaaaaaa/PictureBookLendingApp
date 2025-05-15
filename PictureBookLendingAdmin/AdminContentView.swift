import SwiftUI

struct AdminContentView: View {
    private let bookManagementService = BookManagementService()
    @State private var books: [Book] = []
    
    var body: some View {
        NavigationView {
            List(books) { book in
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.headline)
                    Text(book.author)
                        .font(.subheadline)
                }
            }
            .navigationTitle("管理アプリ")
            .onAppear {
                let book1 = bookManagementService.addBook(
                    title: "はらぺこあおむし",
                    author: "エリック・カール",
                    isbn: "978-4033280103",
                    publishedYear: 1976
                )
                
                let book2 = bookManagementService.addBook(
                    title: "ぐりとぐら",
                    author: "中川李枝子",
                    isbn: "978-4834000825",
                    publishedYear: 1967
                )
                
                books = [book1, book2]
            }
        }
    }
}

struct AdminContentView_Previews: PreviewProvider {
    static var previews: some View {
        AdminContentView()
    }
}
