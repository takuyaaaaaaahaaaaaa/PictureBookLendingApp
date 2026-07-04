import Foundation
import Observation
import PictureBookLendingDomain

/// バックアップ機能に関するエラー
public enum BackupModelError: Error, Equatable, LocalizedError {
    /// アプリが対応していないスキーマバージョンのバックアップを復元しようとした場合のエラー
    case incompatibleSchemaVersion(Int)
    /// 復元処理に失敗した場合のエラー
    case restoreFailed
    
    public var errorDescription: String? {
        switch self {
        case .incompatibleSchemaVersion(let version):
            return "対応していないバックアップ形式です（バージョン\(version)）"
        case .restoreFailed:
            return "データの復元に失敗しました"
        }
    }
}

/// 復元結果のサマリー
public struct RestoreSummary: Equatable, Sendable {
    public let classGroupCount: Int
    public let userCount: Int
    public let bookCount: Int
    public let loanCount: Int
}

/// バックアップのエクスポート/インポートを担当するモデル
///
/// 図書・利用者・組・貸出記録・貸出設定・図書画像をまとめてスナップショット化し、
/// 端末間のデータ引き継ぎ（Apple ID切替・機種変更等）を可能にします。
@Observable
@MainActor
public class BackupModel {
    
    private let bookRepository: BookRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let classGroupRepository: ClassGroupRepositoryProtocol
    private let loanRepository: LoanRepositoryProtocol
    private let loanSettingsRepository: LoanSettingsRepositoryProtocol
    private let imageStorageRepository: ImageStorageRepositoryProtocol
    
    /// イニシャライザ
    /// - Parameters:
    ///   - bookRepository: 図書リポジトリ
    ///   - userRepository: 利用者リポジトリ
    ///   - classGroupRepository: 組リポジトリ
    ///   - loanRepository: 貸出リポジトリ
    ///   - loanSettingsRepository: 貸出設定リポジトリ
    ///   - imageStorageRepository: 図書画像リポジトリ
    public init(
        bookRepository: BookRepositoryProtocol,
        userRepository: UserRepositoryProtocol,
        classGroupRepository: ClassGroupRepositoryProtocol,
        loanRepository: LoanRepositoryProtocol,
        loanSettingsRepository: LoanSettingsRepositoryProtocol,
        imageStorageRepository: ImageStorageRepositoryProtocol
    ) {
        self.bookRepository = bookRepository
        self.userRepository = userRepository
        self.classGroupRepository = classGroupRepository
        self.loanRepository = loanRepository
        self.loanSettingsRepository = loanSettingsRepository
        self.imageStorageRepository = imageStorageRepository
    }
    
    /// 現在のデータからバックアップスナップショットを作成する
    /// - Returns: 作成されたバックアップスナップショット
    /// - Throws: データ取得に失敗した場合はエラーを投げる
    public func createSnapshot() throws -> BackupSnapshot {
        let books = try bookRepository.fetchAll()
        
        var bookImages: [String: Data] = [:]
        for book in books {
            guard let fileName = book.localImageFileName else { continue }
            if let data = imageStorageRepository.loadImageData(fileName: fileName) {
                bookImages[fileName] = data
            }
        }
        
        return BackupSnapshot(
            createdAt: Date(),
            classGroups: try classGroupRepository.fetchAll(),
            users: try userRepository.fetchAll(),
            books: books,
            loans: try loanRepository.fetchAll(),
            loanSettings: loanSettingsRepository.fetch(),
            bookImages: bookImages
        )
    }
    
    /// バックアップスナップショットから復元する
    ///
    /// 復元前に既存の図書・利用者・組・貸出記録を全て削除し、
    /// スナップショットの内容で完全に置き換えます。
    /// 復元処理が途中で失敗した場合は、復元前の状態への復旧を試みます。
    /// - Parameter snapshot: 復元するスナップショット
    /// - Returns: 復元されたデータの件数サマリー
    /// - Throws: スキーマバージョンが非対応、または復元処理に失敗した場合はエラーを投げる
    @discardableResult
    public func restore(from snapshot: BackupSnapshot) throws -> RestoreSummary {
        guard snapshot.schemaVersion <= BackupSnapshot.currentSchemaVersion else {
            throw BackupModelError.incompatibleSchemaVersion(snapshot.schemaVersion)
        }
        
        // 復元が途中で失敗した場合に元の状態へ戻せるよう、事前にバックアップしておく
        let previousSnapshot = try? createSnapshot()
        
        do {
            try deleteAllExistingData()
            try applySnapshotData(snapshot)
            
            return RestoreSummary(
                classGroupCount: snapshot.classGroups.count,
                userCount: snapshot.users.count,
                bookCount: snapshot.books.count,
                loanCount: snapshot.loans.count
            )
        } catch {
            if let previousSnapshot {
                try? deleteAllExistingData()
                try? applySnapshotData(previousSnapshot)
            }
            throw BackupModelError.restoreFailed
        }
    }
    
    /// スナップショットの内容をリポジトリへ投入する
    private func applySnapshotData(_ snapshot: BackupSnapshot) throws {
        for (fileName, data) in snapshot.bookImages {
            try imageStorageRepository.saveImageData(data, fileName: fileName)
        }
        for classGroup in snapshot.classGroups {
            try classGroupRepository.save(classGroup)
        }
        for user in snapshot.users {
            _ = try userRepository.save(user)
        }
        for book in snapshot.books {
            _ = try bookRepository.save(book)
        }
        for loan in snapshot.loans {
            _ = try loanRepository.save(loan)
        }
        try loanSettingsRepository.save(snapshot.loanSettings)
    }
    
    /// 復元前に既存の図書・利用者・組・貸出記録を全て削除する
    private func deleteAllExistingData() throws {
        for loan in try loanRepository.fetchAll() {
            _ = try loanRepository.delete(loan.id)
        }
        for user in try userRepository.fetchAll() {
            _ = try userRepository.delete(user.id)
        }
        for book in try bookRepository.fetchAll() {
            _ = try bookRepository.delete(book.id)
        }
        for classGroup in try classGroupRepository.fetchAll() {
            try classGroupRepository.delete(by: classGroup.id)
        }
    }
}
