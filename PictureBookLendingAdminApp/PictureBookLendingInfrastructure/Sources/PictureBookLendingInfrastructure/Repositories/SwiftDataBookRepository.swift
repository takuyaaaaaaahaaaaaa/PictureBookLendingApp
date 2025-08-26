import Foundation
import PictureBookLendingDomain
import SwiftData

/// SwiftData用絵本リポジトリ実装
///
/// SwiftDataを使用して絵本の永続化を担当するリポジトリ
public final class SwiftDataBookRepository: BookRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext
    
    /// イニシャライザ
    ///
    /// - Parameter modelContext: SwiftData用のモデルコンテキスト
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 絵本を保存する
    ///
    /// - Parameter book: 保存する絵本
    /// - Returns: 保存された絵本
    /// - Throws: 保存に失敗した場合はエラーを投げる
    public func save(_ book: Book) throws -> Book {
        // SwiftDataでは、オブジェクトをモデルコンテキストに挿入してSwiftDataモデルに変換
        let swiftDataBook = SwiftDataBook(
            id: book.id,
            title: book.title,
            author: book.author,
            isbn13: book.isbn13,
            publisher: book.publisher,
            publishedDate: book.publishedDate,
            bookDescription: book.description,
            smallThumbnail: book.smallThumbnail,
            thumbnail: book.thumbnail,
            targetAge: book.targetAge?.rawValue,
            pageCount: book.pageCount,
            categories: book.categories,
            managementNumber: book.managementNumber,
            kanaGroup: book.kanaGroup
        )
        
        modelContext.insert(swiftDataBook)
        
        do {
            try modelContext.save()
            return book
        } catch {
            throw RepositoryError.saveFailed
        }
    }
    
    /// 全ての絵本を取得する
    ///
    /// - Returns: 全ての絵本のリスト
    /// - Throws: 取得に失敗した場合はエラーを投げる
    public func fetchAll() throws -> [Book] {
        do {
            let descriptor = FetchDescriptor<SwiftDataBook>()
            let swiftDataBooks = try modelContext.fetch(descriptor)
            
            // SwiftDataモデルからドメインモデルに変換
            return swiftDataBooks.map { swiftDataBook in
                Book(
                    id: swiftDataBook.id,
                    title: swiftDataBook.title,
                    author: swiftDataBook.author,
                    isbn13: swiftDataBook.isbn13,
                    publisher: swiftDataBook.publisher,
                    publishedDate: swiftDataBook.publishedDate,
                    description: swiftDataBook.bookDescription,
                    smallThumbnail: swiftDataBook.smallThumbnail,
                    thumbnail: swiftDataBook.thumbnail,
                    targetAge: swiftDataBook.targetAge.flatMap {
                        TargetAudience(rawValue: $0)
                    },
                    pageCount: swiftDataBook.pageCount,
                    categories: swiftDataBook.categories,
                    managementNumber: swiftDataBook.managementNumber,
                    kanaGroup: swiftDataBook.kanaGroup
                )
            }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /// IDで絵本を検索する
    ///
    /// - Parameter id: 検索する絵本のID
    /// - Returns: 見つかった絵本（見つからない場合はnil）
    /// - Throws: 検索に失敗した場合はエラーを投げる
    public func findById(_ id: UUID) throws -> Book? {
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
                author: swiftDataBook.author,
                isbn13: swiftDataBook.isbn13,
                publisher: swiftDataBook.publisher,
                publishedDate: swiftDataBook.publishedDate,
                description: swiftDataBook.bookDescription,
                smallThumbnail: swiftDataBook.smallThumbnail,
                thumbnail: swiftDataBook.thumbnail,
                targetAge: swiftDataBook.targetAge.flatMap { TargetAudience(rawValue: $0) },
                pageCount: swiftDataBook.pageCount,
                categories: swiftDataBook.categories,
                managementNumber: swiftDataBook.managementNumber,
                kanaGroup: swiftDataBook.kanaGroup
            )
        } catch {
            throw RepositoryError.fetchFailed
        }
    }
    
    /// 絵本を更新する
    ///
    /// - Parameter book: 更新する絵本
    /// - Returns: 更新された絵本
    /// - Throws: 更新に失敗した場合はエラーを投げる
    public func update(_ book: Book) throws -> Book {
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
            swiftDataBook.managementNumber = book.managementNumber
            swiftDataBook.isbn13 = book.isbn13
            swiftDataBook.publisher = book.publisher
            swiftDataBook.publishedDate = book.publishedDate
            swiftDataBook.bookDescription = book.description
            swiftDataBook.smallThumbnail = book.smallThumbnail
            swiftDataBook.thumbnail = book.thumbnail
            swiftDataBook.targetAge = book.targetAge?.rawValue
            swiftDataBook.pageCount = book.pageCount
            swiftDataBook.categories = book.categories
            swiftDataBook.kanaGroup = book.kanaGroup
            
            try modelContext.save()
            
            return book
        } catch RepositoryError.notFound {
            throw RepositoryError.notFound
        } catch {
            throw RepositoryError.updateFailed
        }
    }
    
    /// 絵本を削除する
    ///
    /// - Parameter id: 削除する絵本のID
    /// - Returns: 削除に成功したかどうか
    /// - Throws: 削除に失敗した場合はエラーを投げる
    public func delete(_ id: UUID) throws -> Bool {
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
