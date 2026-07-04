import PictureBookLendingDomain
import SwiftUI
import UniformTypeIdentifiers

/// バックアップデータのファイルドキュメント
///
/// `.fileExporter` でのエクスポート時に、`BackupSnapshot` をJSONファイルとして書き出すためのラッパー
struct BackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    static let writableContentTypes: [UTType] = [.json]
    
    let snapshot: BackupSnapshot
    
    init(snapshot: BackupSnapshot) {
        self.snapshot = snapshot
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        snapshot = try BackupDocument.decoder.decode(BackupSnapshot.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try BackupDocument.encoder.encode(snapshot)
        return FileWrapper(regularFileWithContents: data)
    }
    
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
