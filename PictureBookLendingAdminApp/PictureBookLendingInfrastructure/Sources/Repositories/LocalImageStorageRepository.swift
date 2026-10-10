import Foundation
import PictureBookLendingDomain

/// Stores registered images in BookImages. An injected directory isolates filesystem tests.
public final class LocalImageStorageRepository: ImageStorageRepositoryProtocol {
    private let directoryURL: URL

    public init(directoryURL: URL = ImageStorageUtility.imageURL(for: "")) {
        self.directoryURL = directoryURL
    }

    private func imageURL(_ fileName: String) throws -> URL {
        guard !fileName.isEmpty, fileName != ".", fileName != "..",
            !fileName.contains("/"), !fileName.contains("\\")
        else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        return directoryURL.appendingPathComponent(fileName)
    }

    public func loadImageData(fileName: String) -> Data? {
        guard let url = try? imageURL(fileName) else { return nil }
        return try? Data(contentsOf: url)
    }

    public func saveImageData(_ data: Data, fileName: String) throws {
        let url = try imageURL(fileName)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    public func deleteImage(fileName: String) throws { try removeIfPresent(try imageURL(fileName)) }
    public func deleteAllImages() throws { try removeIfPresent(directoryURL) }

    private func removeIfPresent(_ url: URL) throws {
        do { try FileManager.default.removeItem(at: url) } catch CocoaError.fileNoSuchFile {
            // Already removed.
        }
    }
}
