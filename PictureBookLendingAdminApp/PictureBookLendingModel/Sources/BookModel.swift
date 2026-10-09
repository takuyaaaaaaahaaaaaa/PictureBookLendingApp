import Foundation
import Observation
import PictureBookLendingDomain

/// 絵本管理に関するエラー
public enum BookModelError: Error, Equatable, LocalizedError {
    /// 指定された絵本が見つからない場合のエラー
    case bookNotFound
    case imageDeletionFailed
    case deletionFailed
    /// 絵本登録に失敗した場合のエラー
    case registrationFailed
    /// 絵本更新に失敗した場合のエラー
    case updateFailed
    /// 管理番号が重複している場合のエラー
    case managementNumberDuplicated(String)
    
    public var errorDescription: String? {
        switch self {
        case .imageDeletionFailed:
            return "図書データは削除しましたが、登録写真の削除に失敗しました。画像が端末内に残っています。設定の端末初期化で図書データの削除を再試行できます（残っている図書も対象になります）。"
        case .deletionFailed:
            return "図書の削除に失敗しました。一部が削除済みの場合があります。"
        case .bookNotFound:
            return "指定された絵本が見つかりません"
        case .registrationFailed:
            return "絵本の登録に失敗しました"
        case .updateFailed:
            return "絵本の更新に失敗しました"
        case .managementNumberDuplicated(let managementNumber):
            return "管理番号「\(managementNumber)」は既に使用されています"
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
    private let imageStorageRepository: ImageStorageRepositoryProtocol
    
    /// キャッシュ用の絵本リスト
    public private(set) var books: [Book] = []
    /// Whether the latest full-catalog read succeeded; an empty failed read must not prune derivatives.
    public private(set) var hasLoadedBooks = false
    
    /// イニシャライザ
    ///
    /// - Parameter repository: 絵本リポジトリ
    public init(repository: BookRepositoryProtocol, imageStorageRepository: ImageStorageRepositoryProtocol) {
        self.repository = repository
        self.imageStorageRepository = imageStorageRepository
        
        // 初期データのロード
        do {
            self.books = try repository.fetchAll()
            hasLoadedBooks = true
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
            hasLoadedBooks = true
        } catch {
            hasLoadedBooks = false
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
        let catalog: [Book]
        do { catalog = try repository.fetchAll() }
        catch { throw BookModelError.deletionFailed }
        guard let book = catalog.first(where: { $0.id == id }) else { throw BookModelError.bookNotFound }
        do {
            guard try repository.delete(id) else { throw BookModelError.deletionFailed }
        } catch { throw BookModelError.deletionFailed }
        books = catalog.filter { $0.id != id }
        hasLoadedBooks = true
        if let fileName = book.localImageFileName,
           !catalog.contains(where: { $0.id != id && $0.localImageFileName == fileName }) {
            do { try imageStorageRepository.deleteImage(fileName: fileName) }
            catch { throw BookModelError.imageDeletionFailed }
        }
        return true
    }
    
    /// 管理番号の重複をチェックする
    ///
    /// 指定された管理番号が既に他の絵本で使用されているかをチェックします。
    ///
    /// - Parameters:
    ///   - managementNumber: チェックする管理番号
    ///   - excludeBookId: チェックから除外する絵本のID（編集時に使用）
    /// - Returns: 重複している場合はその絵本、重複していない場合はnil
    public func findBookByManagementNumber(
        _ managementNumber: String, excluding excludeBookId: UUID? = nil
    ) -> Book? {
        return books.first { book in
            // 除外IDが指定されている場合はそれを除外
            if let excludeId = excludeBookId, book.id == excludeId {
                return false
            }
            
            // 管理番号が一致するかチェック
            return book.managementNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                == managementNumber.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }
    
    /// 全ての絵本を削除する
    ///
    /// 全絵本データを削除します。端末初期化時に使用されます。
    ///
    /// - Returns: 削除された絵本の数
    /// - Throws: 削除に失敗した場合は `BookModelError` を投げます
    public func deleteAllBooks() throws -> Int {
        let catalog: [Book]
        do { catalog = try repository.fetchAll() }
        catch { throw BookModelError.deletionFailed }
        books = catalog
        hasLoadedBooks = true
        for book in catalog {
            do { guard try repository.delete(book.id) else { throw BookModelError.deletionFailed } }
            catch { throw BookModelError.deletionFailed }
            books.removeAll { $0.id == book.id }
        }
        books = []
        hasLoadedBooks = true
        // Only a fully deleted catalog permits deleting old and orphaned photos.
        do { try imageStorageRepository.deleteAllImages() }
        catch { throw BookModelError.imageDeletionFailed }
        return catalog.count
    }
}
