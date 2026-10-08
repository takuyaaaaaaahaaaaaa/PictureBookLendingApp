import CoreGraphics
import CoreML
import CoreVideo
import Foundation
import ImageIO
import Observation
import PictureBookLendingDomain
import PictureBookLendingInfrastructure
/// The index is a disposable derivative of cover images, not part of the book database.
/// A model or preprocessing change invalidates every stored vector.
private struct CoverFeatureIndex: Codable {
    static let version = "FastViTT8F16Headless-1.0-orientedCenterCrop-BGRA-v2"
    struct Entry: Codable {
        let source: String
        let vector: [Float]
    }
    var version = Self.version
    var entries: [UUID: Entry] = [:]
}
struct CoverMatch: Identifiable, Sendable {
    let id: UUID
    let similarity: Float
}
enum CoverRecognitionError: LocalizedError {
    case modelUnavailable
    case invalidImage
    case invalidFeatures
    var errorDescription: String? {
        switch self {
        case .modelUnavailable: "表紙検索モデルを読み込めませんでした"
        case .invalidImage: "画像を読み込めませんでした"
        case .invalidFeatures: "表紙の特徴を取得できませんでした"
        }
    }
}
actor CoverRecognitionEngine {
    private let indexURL: URL
    private let session: URLSession
    private var index: CoverFeatureIndex
    private var model: MLModel?
    init(indexURL: URL? = nil, session: URLSession = .shared) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let resolvedURL = indexURL ?? documents.appendingPathComponent("CoverFeatures-v1.json")
        self.indexURL = resolvedURL
        self.session = session
        if let data = try? Data(contentsOf: resolvedURL),
            let saved = try? JSONDecoder().decode(CoverFeatureIndex.self, from: data),
            saved.version == CoverFeatureIndex.version
        {
            index = saved
        } else {
            index = CoverFeatureIndex()
        }
    }
    func removeBooks(notIn ids: Set<UUID>) throws {
        let previousCount = index.entries.count
        index.entries = index.entries.filter { ids.contains($0.key) }
        if index.entries.count != previousCount { try save() }
    }
    func remove(bookID: UUID) throws {
        guard index.entries.removeValue(forKey: bookID) != nil else { return }
        try save()
    }
    func indexedCount() -> Int { index.entries.count }
    /// Returns false when the book has no usable image. A failed download remains retryable.
    func indexIfNeeded(_ book: Book) async throws -> Bool {
        guard let source = imageSource(for: book) else {
            try remove(bookID: book.id)
            return false
        }
        if index.entries[book.id]?.source == source { return true }
        // Never retain a vector for a cover that has been replaced.
        try remove(bookID: book.id)
        let data: Data
        if let fileName = book.localImageFileName {
            guard let local = ImageStorageUtility.readImageData(fileName: fileName) else {
                return false
            }
            data = local
        } else {
            guard let url = URL(string: source), url.scheme?.lowercased() == "https" else {
                return false
            }
            let (downloaded, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                downloaded.count <= 10_000_000
            else { return false }
            data = downloaded
        }
        let vector = try encode(data)
        index.entries[book.id] = .init(source: source, vector: vector)
        try save()
        return true
    }
    func search(imageData: Data, validBookIDs: Set<UUID>) throws -> [CoverMatch] {
        let query = try encode(imageData)
        return index.entries.compactMap { id, entry -> CoverMatch? in
            guard validBookIDs.contains(id), entry.vector.count == query.count else { return nil }
            let similarity = zip(query, entry.vector).reduce(Float.zero) { $0 + $1.0 * $1.1 }
            return CoverMatch(id: id, similarity: similarity)
        }
        .sorted { $0.similarity > $1.similarity }
        .filter { $0.similarity >= 0.90 }  // Provisional; calibrate with real covers before release.
        .prefix(3)
        .map { $0 }
    }
    private func imageSource(for book: Book) -> String? {
        if let fileName = book.localImageFileName {
            let url = ImageStorageUtility.imageURL(for: fileName)
            guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                  let modified = values.contentModificationDate,
                  let size = values.fileSize else { return nil }
            return "local:\(fileName):\(modified.timeIntervalSince1970):\(size)"
        }
        return book.displayImageSource
    }
    private func save() throws {
        let data = try JSONEncoder().encode(index)
        try data.write(to: indexURL, options: .atomic)
    }
    private func encode(_ data: Data) throws -> [Float] {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1024
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            throw CoverRecognitionError.invalidImage
        }
        let model = try loadModel()
        var buffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]
        guard
            CVPixelBufferCreate(
                kCFAllocatorDefault, 256, 256, kCVPixelFormatType_32BGRA,
                attributes as CFDictionary, &buffer) == kCVReturnSuccess,
            let buffer
        else { throw CoverRecognitionError.invalidImage }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard
            let context = CGContext(
                data: CVPixelBufferGetBaseAddress(buffer), width: 256,
                height: 256, bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                    | CGBitmapInfo.byteOrder32Little.rawValue)
        else {
            throw CoverRecognitionError.invalidImage
        }
        let side = min(image.width, image.height)
        let crop = CGRect(
            x: (image.width - side) / 2, y: (image.height - side) / 2,
            width: side, height: side)
        guard let cropped = image.cropping(to: crop) else {
            throw CoverRecognitionError.invalidImage
        }
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: 256, height: 256))
        let input = try MLDictionaryFeatureProvider(dictionary: [
            "image": MLFeatureValue(pixelBuffer: buffer)
        ])
        guard
            let features = try model.prediction(from: input).featureValue(for: "imageFeatures")?
                .multiArrayValue,
            features.count == 768
        else { throw CoverRecognitionError.invalidFeatures }
        let raw = (0..<features.count).map { features[$0].floatValue }
        let length = sqrt(raw.reduce(Float.zero) { $0 + $1 * $1 })
        guard length.isFinite && length > 0 else { throw CoverRecognitionError.invalidFeatures }
        return raw.map { $0 / length }
    }
    private func loadModel() throws -> MLModel {
        if let model { return model }
        guard
            let url = Bundle.main.url(
                forResource: "FastViTT8F16Headless", withExtension: "mlmodelc")
        else {
            throw CoverRecognitionError.modelUnavailable
        }
        let configuration = MLModelConfiguration()
        #if targetEnvironment(simulator)
            configuration.computeUnits = .cpuOnly
        #else
            configuration.computeUnits = .all
        #endif
        let loaded = try MLModel(contentsOf: url, configuration: configuration)
        model = loaded
        return loaded
    }
}
@Observable
@MainActor
final class CoverRecognitionService {
    static let shared = CoverRecognitionService()
    private let engine = CoverRecognitionEngine()
    @ObservationIgnored private var queuedBooks: [Book]?
    private(set) var preparedCount = 0
    private(set) var pendingCount = 0
    private(set) var isPreparing = false
    /// Safe to invoke again after app restart, restore, image replacement, or a failed download.
    func prepare(books: [Book]) async {
        guard !isPreparing else {
            queuedBooks = books
            return
        }
        isPreparing = true
        defer {
            isPreparing = false
            if let queuedBooks {
                self.queuedBooks = nil
                Task { await self.prepare(books: queuedBooks) }
            }
        }
        try? await engine.removeBooks(notIn: Set(books.map(\.id)))
        preparedCount = 0
        pendingCount = 0
        for book in books {
            if Task.isCancelled { break }
            do {
                if try await engine.indexIfNeeded(book) {
                    preparedCount += 1
                } else {
                    pendingCount += 1
                }
            } catch {
                pendingCount += 1
            }
        }
    }
    func remove(bookID: UUID) async { try? await engine.remove(bookID: bookID) }
    func search(imageData: Data, books: [Book]) async throws -> [CoverMatch] {
        try await engine.search(imageData: imageData, validBookIDs: Set(books.map(\.id)))
    }
}
