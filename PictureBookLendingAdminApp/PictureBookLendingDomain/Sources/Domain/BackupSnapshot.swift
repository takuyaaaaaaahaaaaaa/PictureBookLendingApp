import Foundation

/// バックアップスナップショット
///
/// 図書・利用者・組・貸出記録・貸出設定・図書画像をまとめて1つにしたデータの塊です。
/// 端末変更やApple ID切替に伴うデータ引き継ぎ（エクスポート/インポート）に使用します。
public struct BackupSnapshot: Codable {
    /// このスナップショット形式の現在のバージョン
    public static let currentSchemaVersion = 1
    
    /// スキーマバージョン（将来の互換性チェック用）
    public var schemaVersion: Int
    /// 作成日時
    public var createdAt: Date
    /// 組のリスト
    public var classGroups: [ClassGroup]
    /// 利用者のリスト
    public var users: [User]
    /// 図書のリスト
    public var books: [Book]
    /// 貸出記録のリスト
    public var loans: [Loan]
    /// 貸出設定
    public var loanSettings: LoanSettings
    /// 図書のローカル画像データ（ファイル名 → 画像データ）
    public var bookImages: [String: Data]
    
    /// イニシャライザ
    /// - Parameters:
    ///   - schemaVersion: スキーマバージョン（デフォルトは現在のバージョン）
    ///   - createdAt: 作成日時
    ///   - classGroups: 組のリスト
    ///   - users: 利用者のリスト
    ///   - books: 図書のリスト
    ///   - loans: 貸出記録のリスト
    ///   - loanSettings: 貸出設定
    ///   - bookImages: 図書のローカル画像データ
    public init(
        schemaVersion: Int = BackupSnapshot.currentSchemaVersion,
        createdAt: Date,
        classGroups: [ClassGroup],
        users: [User],
        books: [Book],
        loans: [Loan],
        loanSettings: LoanSettings,
        bookImages: [String: Data]
    ) {
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.classGroups = classGroups
        self.users = users
        self.books = books
        self.loans = loans
        self.loanSettings = loanSettings
        self.bookImages = bookImages
    }
}
