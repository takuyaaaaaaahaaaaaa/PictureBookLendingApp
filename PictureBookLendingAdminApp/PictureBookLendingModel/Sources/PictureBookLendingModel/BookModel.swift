import Foundation
import Observation
import PictureBookLendingDomain

/// 絵本管理に関するエラー
public enum BookModelError: Error, Equatable, LocalizedError {
    /// 指定された絵本が見つからない場合のエラー
    case bookNotFound
    /// 絵本登録に失敗した場合のエラー
    case registrationFailed
    /// 絵本更新に失敗した場合のエラー
    case updateFailed
    
    public var errorDescription: String? {
        switch self {
        case .bookNotFound:
            return "指定された絵本が見つかりません"
        case .registrationFailed:
            return "絵本の登録に失敗しました"
        case .updateFailed:
            return "絵本の更新に失敗しました"
        }
    }
}

/// 絵本管理モデル
///
/// 絵本のCRUD操作を管理するモデルクラスです。
/// - 絵本の登録
/// - 絵本の一覧取得
/// - 絵本のID検索
/// - 絵本情報の更新
/// - 絵本の削除
/// などの機能を提供します。
@Observable
@MainActor
public class BookModel {
    
    /// 絵本リポジトリ
    private let repository: BookRepositoryProtocol
    
    /// キャッシュ用の絵本リスト
    public private(set) var books: [Book] = []
    
    /// イニシャライザ
    ///
    /// - Parameter repository: 絵本リポジトリ
    public init(repository: BookRepositoryProtocol) {
        self.repository = repository
        
        // 初期データのロード
        do {
            self.books = try repository.fetchAll()
        } catch {
            print("初期データのロードに失敗しました: \(error)")
            self.books = []
        }
    }
    
    /// 絵本を登録する
    ///
    /// 新しい絵本を管理リストに追加します。
    ///
    /// - Parameter book: 登録する絵本の情報
    /// - Returns: 登録された絵本（IDが割り当てられます）
    /// - Throws: 登録に失敗した場合は `BookModelError.registrationFailed` を投げます
    public func registerBook(_ book: Book) throws -> Book {
        do {
            // リポジトリに保存
            let savedBook = try repository.save(book)
            
            // キャッシュに追加
            books.append(savedBook)
            
            return savedBook
        } catch {
            throw BookModelError.registrationFailed
        }
    }
    
    /// 全ての絵本を取得する
    ///
    /// 管理中の全絵本リストを返します。
    ///
    /// - Returns: 全ての絵本の配列
    public func getAllBooks() -> [Book] {
        return books
    }
    
    /// 絵本リストを最新の状態に更新する
    ///
    /// リポジトリから最新のデータを取得して内部キャッシュを更新します。
    public func refreshBooks() {
        do {
            books = try repository.fetchAll()
        } catch {
            print("絵本リストの更新に失敗しました: \(error)")
        }
    }
    
    /// 指定IDの絵本を検索する
    ///
    /// IDを指定して絵本を検索します。
    ///
    /// - Parameter id: 検索する絵本のID
    /// - Returns: 見つかった絵本（見つからない場合はnil）
    public func findBookById(_ id: UUID) -> Book? {
        // キャッシュから検索
        if let cachedBook = books.first(where: { $0.id == id }) {
            return cachedBook
        }
        
        // リポジトリから検索
        do {
            return try repository.findById(id)
        } catch {
            print("絵本の検索に失敗しました: \(error)")
            return nil
        }
    }
    
    /// 絵本情報を更新する
    ///
    /// 指定された絵本の情報を更新します。
    ///
    /// - Parameter book: 更新する絵本情報（IDで既存の絵本を特定）
    /// - Returns: 更新された絵本
    /// - Throws: 更新に失敗した場合は `BookModelError` を投げます
    public func updateBook(_ book: Book) throws -> Book {
        do {
            // リポジトリで更新
            let updatedBook = try repository.update(book)
            
            // キャッシュも更新
            if let index = books.firstIndex(where: { $0.id == book.id }) {
                books[index] = updatedBook
            } else {
                // キャッシュになければ追加
                books.append(updatedBook)
            }
            
            return updatedBook
        } catch RepositoryError.notFound {
            throw BookModelError.bookNotFound
        } catch {
            throw BookModelError.updateFailed
        }
    }
    
    /// 絵本を削除する
    ///
    /// 指定されたIDの絵本を削除します。
    ///
    /// - Parameter id: 削除する絵本のID
    /// - Returns: 削除に成功したかどうか
    /// - Throws: 削除対象が見つからない場合は `BookModelError.bookNotFound` を投げます
    public func deleteBook(_ id: UUID) throws -> Bool {
        do {
            // リポジトリから削除
            let result = try repository.delete(id)
            
            // キャッシュからも削除
            books.removeAll(where: { $0.id == id })
            
            return result
        } catch RepositoryError.notFound {
            throw BookModelError.bookNotFound
        } catch {
            throw BookModelError.updateFailed
        }
    }
}
