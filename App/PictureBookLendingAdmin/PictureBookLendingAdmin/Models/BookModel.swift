import Foundation
import PictureBookLendingCore

/**
 * 絵本管理に関するエラー
 */
enum BookModelError: Error, Equatable {
    /// 指定された絵本が見つからない場合のエラー
    case bookNotFound
    /// 絵本登録に失敗した場合のエラー
    case registrationFailed
    /// 絵本更新に失敗した場合のエラー
    case updateFailed
}

/**
 * 絵本管理モデル
 *
 * 絵本のCRUD操作を管理するモデルクラスです。
 * - 絵本の登録
 * - 絵本の一覧取得
 * - 絵本のID検索
 * - 絵本情報の更新
 * - 絵本の削除
 * などの機能を提供します。
 */
class BookModel {
    
    /// 管理している絵本のリスト
    private(set) var books: [Book] = []
    
    /**
     * 絵本を登録する
     * 
     * 新しい絵本を管理リストに追加します。
     *
     * - Parameter book: 登録する絵本の情報
     * - Returns: 登録された絵本（IDが割り当てられます）
     * - Throws: 登録に失敗した場合は `BookModelError.registrationFailed` を投げます
     */
    func registerBook(_ book: Book) throws -> Book {
        // 重複IDをチェック
        if let _ = books.first(where: { $0.id == book.id }) {
            throw BookModelError.registrationFailed
        }
        
        // 追加
        books.append(book)
        return book
    }
    
    /**
     * 全ての絵本を取得する
     *
     * 管理中の全絵本リストを返します。
     *
     * - Returns: 全ての絵本の配列
     */
    func getAllBooks() -> [Book] {
        return books
    }
    
    /**
     * 指定IDの絵本を検索する
     *
     * IDを指定して絵本を検索します。
     *
     * - Parameter id: 検索する絵本のID
     * - Returns: 見つかった絵本（見つからない場合はnil）
     */
    func findBookById(_ id: UUID) -> Book? {
        return books.first { $0.id == id }
    }
    
    /**
     * 絵本情報を更新する
     *
     * 指定された絵本の情報を更新します。
     *
     * - Parameter book: 更新する絵本情報（IDで既存の絵本を特定）
     * - Returns: 更新された絵本
     * - Throws: 更新に失敗した場合は `BookModelError` を投げます
     */
    func updateBook(_ book: Book) throws -> Book {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else {
            throw BookModelError.bookNotFound
        }
        
        books[index] = book
        return book
    }
    
    /**
     * 絵本を削除する
     *
     * 指定されたIDの絵本を削除します。
     *
     * - Parameter id: 削除する絵本のID
     * - Returns: 削除に成功したかどうか
     * - Throws: 削除対象が見つからない場合は `BookModelError.bookNotFound` を投げます
     */
    func deleteBook(_ id: UUID) throws -> Bool {
        guard let index = books.firstIndex(where: { $0.id == id }) else {
            throw BookModelError.bookNotFound
        }
        
        books.remove(at: index)
        return true
    }
}