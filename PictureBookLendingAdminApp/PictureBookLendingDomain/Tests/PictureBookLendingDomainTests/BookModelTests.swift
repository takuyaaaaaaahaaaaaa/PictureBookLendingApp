import Testing
import Foundation
@testable import PictureBookLendingDomain

/**
 * BookModelテストケース
 *
 * 絵本管理モデルの各機能をテストするためのケース集です。
 * - 絵本の登録
 * - 絵本の一覧取得
 * - 絵本のID検索
 * - 絵本情報の更新
 * - 絵本の削除
 * などの機能をテストします。
 */
struct BookModelTests {
    
    private let mockRepository: MockBookRepository
    private let bookModel: BookModel
    
    init() {
        mockRepository = MockBookRepository()
        bookModel = BookModel(repository: mockRepository)
    }
    
    /**
     * 書籍登録機能のテスト
     *
     * 新しい絵本を登録し、正しく登録されることを確認します。
     */
    @Test
    func registerBook() throws {
        // 1. Arrange - 準備
        let book = Book(title: "はらぺこあおむし", author: "エリック・カール")
        
        // 2. Act - 実行
        let registeredBook = try bookModel.registerBook(book)
        
        // 3. Assert - 検証
        #expect(registeredBook.title == "はらぺこあおむし")
        #expect(registeredBook.author == "エリック・カール")
        #expect(!registeredBook.id.uuidString.isEmpty)
        #expect(bookModel.books.count == 1)
    }
    
    /**
     * 全書籍取得機能のテスト
     *
     * 複数の絵本を登録し、全ての絵本が取得できることを確認します。
     */
    @Test
    func getAllBooks() throws {
        // 1. Arrange - 準備
        let book1 = Book(title: "はらぺこあおむし", author: "エリック・カール")
        let book2 = Book(title: "ぐりとぐら", author: "中川李枝子")
        
        // 2. Act - 実行
        _ = try bookModel.registerBook(book1)
        _ = try bookModel.registerBook(book2)
        let books = bookModel.getAllBooks()
        
        // 3. Assert - 検証
        #expect(books.count == 2)
        #expect(Set(books.map { $0.title }) == Set(["はらぺこあおむし", "ぐりとぐら"]))
    }
    
    /**
     * 書籍ID検索機能のテスト
     *
     * IDを指定して絵本を検索し、正しい絵本が取得できることを確認します。
     */
    @Test
    func findBookById() throws {
        // 1. Arrange - 準備
        let book = Book(title: "はらぺこあおむし", author: "エリック・カール")
        let registeredBook = try bookModel.registerBook(book)
        let id = registeredBook.id
        
        // 2. Act - 実行
        let foundBook = bookModel.findBookById(id)
        
        // 3. Assert - 検証
        #expect(foundBook != nil)
        #expect(foundBook?.title == "はらぺこあおむし")
    }
    
    /**
     * 書籍更新機能のテスト
     *
     * 登録済みの絵本情報を更新し、正しく更新されることを確認します。
     */
    @Test
    func updateBook() throws {
        // 1. Arrange - 準備
        let book = Book(title: "はらぺこあおむし", author: "エリック・カール")
        let registeredBook = try bookModel.registerBook(book)
        let id = registeredBook.id
        
        let updatedBookInfo = Book(id: id, title: "The Very Hungry Caterpillar", author: "Eric Carle")
        
        // 2. Act - 実行
        let updatedBook = try bookModel.updateBook(updatedBookInfo)
        
        // 3. Assert - 検証
        #expect(updatedBook.title == "The Very Hungry Caterpillar")
        #expect(updatedBook.author == "Eric Carle")
        #expect(bookModel.books.count == 1) // 数は変わらない
        #expect(bookModel.findBookById(id)?.title == "The Very Hungry Caterpillar")
    }
    
    /**
     * 書籍削除機能のテスト
     *
     * 登録済みの絵本を削除し、正しく削除されることを確認します。
     */
    @Test
    func deleteBook() throws {
        // 1. Arrange - 準備
        let book = Book(title: "はらぺこあおむし", author: "エリック・カール")
        let registeredBook = try bookModel.registerBook(book)
        let id = registeredBook.id
        
        // 2. Act - 実行
        let result = try bookModel.deleteBook(id)
        
        // 3. Assert - 検証
        #expect(result == true)
        #expect(bookModel.books.count == 0)
        #expect(bookModel.findBookById(id) == nil)
    }
    
    /**
     * 存在しない書籍削除時のエラーテスト
     *
     * 存在しない絵本IDを指定して削除を試みた場合、適切なエラーが発生することを確認します。
     */
    @Test
    func deleteNonExistingBook() throws {
        // 1. Arrange - 準備
        let nonExistingId = UUID()
        
        // 2. Act & Assert - 実行と検証
        #expect(throws: BookModelError.bookNotFound) {
            try bookModel.deleteBook(nonExistingId)
        }
    }
}
