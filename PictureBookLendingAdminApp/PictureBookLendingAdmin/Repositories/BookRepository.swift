import Foundation
import PictureBookLendingDomain
import SwiftData

/**
 * SwiftData用書籍リポジトリ実装
 *
 * SwiftDataを使用して絵本の永続化を担当するリポジトリ
 */
class SwiftDataBookRepository: BookRepository {
    private let modelContext: ModelContext
    
    /**
     * イニシャライザ
     *
     * - Parameter modelContext: SwiftData用のモデルコンテキスト
     */
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /**
     * 絵本を保存する
     *
     * - Parameter book: 保存する絵本
     * - Returns: 保存された絵本
     * - Throws: 保存に失敗した場合はエラーを投げる
     */
    func save(_ book: Book) throws -> Book {
        // SwiftDataでは、オブジェクトをモデルコンテキストに挿入してSwiftDataモデルに変換
        let swiftDataBook = SwiftDataBook(
            id: book.id,
            title: book.title,
            author: book.author
        )
        
        modelContext.insert(swiftDataBook)
        
        do {
            try modelContext.save()
            return book
        } catch {
            throw RepositoryError.saveFailed
        }
    }
    
    /**
     * 全ての絵本を取得する
     *
     * - Returns: 全ての絵本のリスト
     * - Throws: 取得に失敗した場合はエラーを投げる
     */
    func fetchAll() throws -> [Book] {
        do {
            let descriptor = FetchDescriptor<SwiftDataBook>()
            let swiftDataBooks = try modelContext.fetch(descriptor)
            
            // SwiftDataモデルからドメインモデルに変換
            return swiftDataBooks.map { swiftDataBook in
                Book(
                    id: swiftDataBook.id,
                    title: swiftDataBook.title,
                    author: swiftDataBook.author
                )
            }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /**
     * IDで絵本を検索する
     *
     * - Parameter id: 検索する絵本のID
     * - Returns: 見つかった絵本（見つからない場合はnil）
     * - Throws: 検索に失敗した場合はエラーを投げる
     */
    func findById(_ id: UUID) throws -> Book? {
        do {
            let predicate = #Predicate<SwiftDataBook> { $0.id == id }
            let descriptor = FetchDescriptor<SwiftDataBook>(predicate: predicate)
            
            let swiftDataBooks = try modelContext.fetch(descriptor)
            guard let swiftDataBook = swiftDataBooks.first else {
                return nil
            }
            
            return Book(
                id: swiftDataBook.id,
                title: swiftDataBook.title,
                author: swiftDataBook.author
            )
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /**
     * 絵本を更新する
     *
     * - Parameter book: 更新する絵本
     * - Returns: 更新された絵本
     * - Throws: 更新に失敗した場合はエラーを投げる
     */
    func update(_ book: Book) throws -> Book {
        do {
            let predicate = #Predicate<SwiftDataBook> { $0.id == book.id }
            let descriptor = FetchDescriptor<SwiftDataBook>(predicate: predicate)
            
            let swiftDataBooks = try modelContext.fetch(descriptor)
            guard let swiftDataBook = swiftDataBooks.first else {
                throw RepositoryError.notFound
            }
            
            // プロパティを更新
            swiftDataBook.title = book.title
            swiftDataBook.author = book.author
            
            try modelContext.save()
            
            return book
        } catch RepositoryError.notFound {
            throw RepositoryError.notFound
        } catch {
            throw RepositoryError.updateFailed
        }
    }
    
    /**
     * 絵本を削除する
     *
     * - Parameter id: 削除する絵本のID
     * - Returns: 削除に成功したかどうか
     * - Throws: 削除に失敗した場合はエラーを投げる
     */
    func delete(_ id: UUID) throws -> Bool {
        do {
            let predicate = #Predicate<SwiftDataBook> { $0.id == id }
            let descriptor = FetchDescriptor<SwiftDataBook>(predicate: predicate)
            
            let swiftDataBooks = try modelContext.fetch(descriptor)
            guard let swiftDataBook = swiftDataBooks.first else {
                throw RepositoryError.notFound
            }
            
            modelContext.delete(swiftDataBook)
            try modelContext.save()
            
            return true
        } catch RepositoryError.notFound {
            throw RepositoryError.notFound
        } catch {
            throw RepositoryError.deleteFailed
        }
    }
}

/**
 * SwiftData用の書籍モデル
 *
 * SwiftDataで永続化するための書籍モデル
 */
@Model
final class SwiftDataBook {
    var id: UUID
    var title: String
    var author: String
    
    init(id: UUID, title: String, author: String) {
        self.id = id
        self.title = title
        self.author = author
    }
}