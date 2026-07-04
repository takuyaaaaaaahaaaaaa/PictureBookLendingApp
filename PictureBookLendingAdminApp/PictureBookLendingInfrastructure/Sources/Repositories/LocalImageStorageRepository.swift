import Foundation
import PictureBookLendingDomain

/// ローカルファイルシステムを使った図書画像リポジトリ実装
///
/// `ImageStorageUtility` が管理するDocuments配下の画像ファイルを
/// バイナリのまま読み書きします。
public final class LocalImageStorageRepository: ImageStorageRepositoryProtocol {
    public init() {}
    
    public func loadImageData(fileName: String) -> Data? {
        ImageStorageUtility.readImageData(fileName: fileName)
    }
    
    public func saveImageData(_ data: Data, fileName: String) throws {
        try ImageStorageUtility.writeImageData(data, fileName: fileName)
    }
}
