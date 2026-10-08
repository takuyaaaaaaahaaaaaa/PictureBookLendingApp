import CoreGraphics
import CoreImage
import CoreML
import CoreVideo
import Foundation
import ImageIO
import Observation
import PictureBookLendingDomain
import PictureBookLendingInfrastructure
import Vision

/// The index is a disposable derivative of cover images, not part of the book database.
/// A model or preprocessing change invalidates every stored vector.
private struct CoverFeatureIndex: Codable {
    static let version = "FastViTT8F16Headless-1.0-coverRectification-BGRA-v3"
    struct Entry: Codable {
        let source: String
        let vector: [Float]
        let croppedVector: [Float]?
        var cropID: UUID? = nil
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
private struct ManualCoverCrop: Codable {
    let id: UUID
    let source: String
    var imageData: Data?  // Legacy inline snapshot, migrated on first actor access.
    let rect: CGRect
}

struct LiveCoverConfirmation {
    private var lastID: UUID?
    private(set) var count = 0
    mutating func accept(_ id: UUID?) -> Bool {
        guard let id else { lastID = nil; count = 0; return false }
        count = lastID == id ? count + 1 : 1
        lastID = id
        return count >= 2
    }
}

actor CoverRecognitionEngine {
    private let indexURL: URL
    private let cropsURL: URL
    private var crops: [UUID: ManualCoverCrop] = [:]
    private var loaded = false
    private let cropImagesURL: URL
    private let session: URLSession
    private var index = CoverFeatureIndex()
    private var model: MLModel?
    init(indexURL: URL? = nil, session: URLSession = .shared) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let resolvedURL = indexURL ?? documents.appendingPathComponent("CoverFeatures-v1.json")
        self.indexURL = resolvedURL
        cropsURL = resolvedURL.appendingPathExtension("crops.json")
        cropImagesURL = resolvedURL.appendingPathExtension("crop-images")
        self.session = session
    }
    /// Disk I/O runs on this actor, never in the MainActor service initializer.
    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        crops = (try? JSONDecoder().decode([UUID: ManualCoverCrop].self,
            from: Data(contentsOf: cropsURL))) ?? [:]
        if let data = try? Data(contentsOf: indexURL),
            let saved = try? JSONDecoder().decode(CoverFeatureIndex.self, from: data),
            saved.version == CoverFeatureIndex.version {
            index = saved
        }
        // Keep legacy inline bytes until metadata has been committed successfully.
        if crops.values.contains(where: { $0.imageData != nil }) {
            try? saveCrops()
        }
    }
    private func cropImageURL(_ crop: ManualCoverCrop) -> URL {
        cropImagesURL.appendingPathComponent(crop.id.uuidString).appendingPathExtension("image")
    }
    private func cropData(_ crop: ManualCoverCrop) throws -> Data {
        if let legacy = crop.imageData { return legacy }
        return try Data(contentsOf: cropImageURL(crop))
    }
    func removeBooks(notIn ids: Set<UUID>) throws {
        loadIfNeeded()
        let oldCrops = crops
        let removedCrops = crops.filter { !ids.contains($0.key) }.map(\.value)
        crops = crops.filter { ids.contains($0.key) }
        if !removedCrops.isEmpty {
            do { try saveCrops() } catch { crops = oldCrops; throw error }
            for crop in removedCrops { try? FileManager.default.removeItem(at: cropImageURL(crop)) }
        }
        let previous = index.entries
        index.entries = index.entries.filter { ids.contains($0.key) }
        if index.entries.count != previous.count {
            do { try save() } catch { index.entries = previous; throw error }
        }
    }
    func remove(bookID: UUID) throws {
        loadIfNeeded()
        if let crop = crops.removeValue(forKey: bookID) {
            do { try saveCrops() } catch { crops[bookID] = crop; throw error }
            try? FileManager.default.removeItem(at: cropImageURL(crop))
        }
        if let previous = index.entries.removeValue(forKey: bookID) {
            do { try save() } catch { index.entries[bookID] = previous; throw error }
        }
    }
    func indexedCount() -> Int { loadIfNeeded(); return index.entries.count }
    /// Returns false when the book has no usable image. A failed download remains retryable.
    func indexIfNeeded(_ book: Book) async throws -> Bool {
        loadIfNeeded()
        guard let source = imageSource(for: book) else {
            try remove(bookID: book.id)
            return false
        }
        let manual = crops[book.id].flatMap { $0.source == source ? $0 : nil }
        if let existing = index.entries[book.id], existing.source == source,
            existing.cropID == manual?.id { return true }
        if let manual {
            let image = try croppedImage(try decodedImage(cropData(manual)), rect: manual.rect)
            index.entries[book.id] = .init(source: source, vector: try encode(image),
                croppedVector: nil, cropID: manual.id)
            try save()
            return true
        }
        // Never retain a vector for a cover that has been replaced.
        try remove(bookID: book.id)
        guard let data = try await originalImageData(for: book, source: source) else { return false }
        // A user may have saved a crop while the external image download was suspended.
        guard imageSource(for: book) == source else { return false }
        if crops[book.id]?.source == source { return try await indexIfNeeded(book) }
        let vector = try encode(data)
        let croppedVector =
            book.localImageFileName != nil
            ? try encode(data, detectCover: true) : nil
        index.entries[book.id] = .init(source: source, vector: vector, croppedVector: croppedVector)
        try save()
        return true
    }
    func search(
        imageData: Data, validBookIDs: Set<UUID>, detectCover: Bool = false
    ) throws -> [CoverMatch] {
        try rank(imageData: imageData, validBookIDs: validBookIDs, detectCover: detectCover)
            .filter { $0.similarity >= 0.70 }  // User-requested trial after manual crop correction; not a calibrated confidence.
            .prefix(3)
            .map { $0 }
    }
    private func rank(
        imageData: Data, validBookIDs: Set<UUID>, detectCover: Bool
    ) throws -> [CoverMatch] {
        loadIfNeeded()
        let image = try decodedImage(imageData)
        var queries = [try encode(image)]
        if detectCover { queries.append(try encode(rectifiedCover(in: image) ?? image)) }
        return index.entries.compactMap { id, entry -> CoverMatch? in
            guard validBookIDs.contains(id), entry.vector.count == queries[0].count else { return nil }
            let stored = [entry.vector] + [entry.croppedVector].compactMap { $0 }
            let similarities = queries.flatMap { query in
                stored.filter { $0.count == query.count }.map { Self.dot(query, $0) }
            }
            return similarities.max().map { CoverMatch(id: id, similarity: $0) }
        }
        .sorted { $0.similarity > $1.similarity }
    }
    private static func dot(_ lhs: [Float], _ rhs: [Float]) -> Float {
        zip(lhs, rhs).reduce(Float.zero) { $0 + $1.0 * $1.1 }
    }
    /// nil when the image cannot be used: missing file, non-HTTPS URL, bad response or oversize.
    private func originalImageData(for book: Book, source: String) async throws -> Data? {
        if let fileName = book.localImageFileName {
            return ImageStorageUtility.readImageData(fileName: fileName)
        }
        guard let url = URL(string: source), url.scheme?.lowercased() == "https" else { return nil }
        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 10_000_000 else {
            return nil
        }
        return data
    }
    private func imageSource(for book: Book) -> String? {
        if let fileName = book.localImageFileName {
            let url = ImageStorageUtility.imageURL(for: fileName)
            guard
                let values = try? url.resourceValues(forKeys: [
                    .contentModificationDateKey, .fileSizeKey,
                ]),
                let modified = values.contentModificationDate,
                let size = values.fileSize
            else { return nil }
            return "local:\(fileName):\(modified.timeIntervalSince1970):\(size)"
        }
        return book.displayImageSource
    }
    private func saveCrops() throws {
        var metadata = crops
        if crops.values.contains(where: { $0.imageData != nil }) {
            try FileManager.default.createDirectory(at: cropImagesURL, withIntermediateDirectories: true)
        }
        for (id, crop) in crops where crop.imageData != nil {
            try crop.imageData?.write(to: cropImageURL(crop), options: .atomic)
            metadata[id]?.imageData = nil
        }
        try JSONEncoder().encode(metadata).write(to: cropsURL, options: .atomic)
        crops = metadata
    }
    private func croppedImage(_ image: CGImage, rect: CGRect) throws -> CGImage {
        guard rect.minX.isFinite, rect.minY.isFinite, rect.width.isFinite, rect.height.isFinite,
            rect.minX >= 0, rect.minY >= 0, rect.maxX <= 1.000001, rect.maxY <= 1.000001,
            rect.width >= 0.049999, rect.height >= 0.049999 else { throw CoverRecognitionError.invalidImage }
        let pixels = CGRect(x: rect.minX * Double(image.width), y: rect.minY * Double(image.height),
            width: rect.width * Double(image.width), height: rect.height * Double(image.height))
        guard let crop = image.cropping(to: pixels.integral) else { throw CoverRecognitionError.invalidImage }
        return crop
    }
    func approveRegisteredPhoto(_ book: Book) throws {
        guard let fileName = book.localImageFileName,
              let data = ImageStorageUtility.readImageData(fileName: fileName),
              let source = imageSource(for: book) else { throw CoverRecognitionError.invalidImage }
        try saveManualCrop(book, imageData: data, source: source,
            rect: CGRect(x: 0, y: 0, width: 1, height: 1))
    }
    func saveManualCrop(_ book: Book, imageData: Data, source: String, rect: CGRect) throws {
        loadIfNeeded()
        guard imageSource(for: book) == source else { throw CoverRecognitionError.invalidImage }
        let image = try croppedImage(try decodedImage(imageData), rect: rect)
        let vector = try encode(image)
        let crop = ManualCoverCrop(id: UUID(), source: source, imageData: imageData, rect: rect)
        let previous = crops[book.id]
        crops[book.id] = crop
        do { try saveCrops() } catch {
            crops[book.id] = previous
            try? FileManager.default.removeItem(at: cropImageURL(crop))
            throw error
        }
        if let previous { try? FileManager.default.removeItem(at: cropImageURL(previous)) }
        // Revision mismatch causes prepare() to rebuild if the index write is interrupted.
        let oldEntry = index.entries[book.id]
        index.entries[book.id] = .init(source: source, vector: vector, croppedVector: nil, cropID: crop.id)
        do { try save() } catch { index.entries[book.id] = oldEntry; throw error }
    }
    private func save() throws {
        let data = try JSONEncoder().encode(index)
        try data.write(to: indexURL, options: .atomic)
    }
    private func decodedImage(_ data: Data) throws -> CGImage {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1024,
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            throw CoverRecognitionError.invalidImage
        }
        return image
    }
    private func encode(_ data: Data, detectCover: Bool = false) throws -> [Float] {
        let image = try decodedImage(data)
        return try encode(detectCover ? (rectifiedCover(in: image) ?? image) : image)
    }
    /// Shared by inference and the debug inspector so it displays the actual preprocessing.
    private func inputBuffer(for preparedImage: CGImage) throws -> CVPixelBuffer {
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
        let side = min(preparedImage.width, preparedImage.height)
        let crop = CGRect(
            x: (preparedImage.width - side) / 2, y: (preparedImage.height - side) / 2,
            width: side, height: side)
        guard let cropped = preparedImage.cropping(to: crop) else {
            throw CoverRecognitionError.invalidImage
        }
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: 256, height: 256))
        return buffer
    }
    private func encode(_ image: CGImage) throws -> [Float] {
        let model = try loadModel()
        let buffer = try inputBuffer(for: image)
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
    private func rectifiedCover(in image: CGImage) -> CGImage? {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 4
        request.minimumConfidence = 0.8
        request.minimumSize = 0.25
        request.minimumAspectRatio = 0.35
        request.maximumAspectRatio = 1
        guard (try? VNImageRequestHandler(cgImage: image).perform([request])) != nil,
            let rectangle = request.results?
                .filter({ $0.boundingBox.width * $0.boundingBox.height >= 0.18 })
                .max(by: {
                    $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width
                        * $1.boundingBox.height
                })
        else { return nil }
        let source = CIImage(cgImage: image)
        let extent = source.extent
        func point(_ normalized: CGPoint) -> CIVector {
            CIVector(
                x: extent.minX + normalized.x * extent.width,
                y: extent.minY + normalized.y * extent.height)
        }
        let filter = CIFilter(name: "CIPerspectiveCorrection")
        filter?.setValue(source, forKey: kCIInputImageKey)
        filter?.setValue(point(rectangle.topLeft), forKey: "inputTopLeft")
        filter?.setValue(point(rectangle.topRight), forKey: "inputTopRight")
        filter?.setValue(point(rectangle.bottomLeft), forKey: "inputBottomLeft")
        filter?.setValue(point(rectangle.bottomRight), forKey: "inputBottomRight")
        guard let corrected = filter?.outputImage else { return nil }
        return CIContext().createCGImage(corrected, from: corrected.extent)
    }
    #if DEBUG
        /// Read-only reconstruction: old indexes contain vectors, not the input pixels.
        func inspectRegistration(_ book: Book) async throws -> CoverRegistrationInspection {
            loadIfNeeded()
            guard let source = imageSource(for: book) else { throw CoverRecognitionError.invalidImage }
            let manual = crops[book.id].flatMap { $0.source == source ? $0 : nil }
            let data: Data
            if let manual {
                data = try cropData(manual)
            } else if let original = try await originalImageData(for: book, source: source) {
                data = original
            } else {
                throw CoverRecognitionError.invalidImage
            }
            let image = try decodedImage(data)
            // External product covers have always used the original-image path only.
            let rectified = try manual.map { try croppedImage(image, rect: $0.rect) }
                ?? (book.localImageFileName != nil ? rectifiedCover(in: image) : nil)
            let stored = index.entries[book.id]
            let originalVector = try encode(image)
            let hasRectifiedSide = manual != nil || book.localImageFileName != nil
            let rectifiedVector = hasRectifiedSide ? try encode(rectified ?? image) : nil
            func similarity(_ lhs: [Float]?, _ rhs: [Float]?) -> Float? {
                guard let lhs, let rhs, lhs.count == rhs.count else { return nil }
                return Self.dot(lhs, rhs)
            }
            func png(_ image: CGImage) throws -> Data {
                try image.encodedData(type: "public.png")
            }
            func modelInput(_ image: CGImage) throws -> Data {
                let buffer = try inputBuffer(for: image)
                let ciImage = CIImage(cvPixelBuffer: buffer)
                guard let pixels = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
                    throw CoverRecognitionError.invalidImage
                }
                return try png(pixels)
            }
            return try CoverRegistrationInspection(
                sourceImage: png(image),
                originalModelInput: modelInput(image),
                rectifiedImage: rectified.map { try png($0) },
                rectifiedModelInput: hasRectifiedSide ? modelInput(rectified ?? image) : nil,
                originalSimilarity: manual == nil ? similarity(originalVector, stored?.vector) : nil,
                rectifiedSimilarity: similarity(rectifiedVector, manual != nil ? stored?.vector : stored?.croppedVector),
                sourceMatchesIndex: stored?.source == source,
                isRemote: book.localImageFileName == nil,
                sourceIdentity: source,
                manualRect: manual?.rect
            )
        }
    #endif
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
    private let engine: CoverRecognitionEngine
    init(engine: CoverRecognitionEngine = CoverRecognitionEngine()) { self.engine = engine }
    @ObservationIgnored private var queuedBooks: [Book]?
    private(set) var preparedCount = 0
    private(set) var pendingCount = 0
    private(set) var isPreparing = false
    /// Safe to invoke again after app restart, restore, image replacement, or a failed download.
    func prepare(books: [Book], isComplete: Bool) async {
        guard isComplete else { return }
        guard !isPreparing else {
            queuedBooks = books
            return
        }
        isPreparing = true
        defer {
            isPreparing = false
            if let queuedBooks {
                self.queuedBooks = nil
                Task { await self.prepare(books: queuedBooks, isComplete: true) }
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
    func search(
        imageData: Data, books: [Book], detectCover: Bool = false
    ) async throws -> [CoverMatch] {
        try await engine.search(
            imageData: imageData, validBookIDs: Set(books.map(\.id)), detectCover: detectCover)
    }
    func approveRegisteredPhoto(_ book: Book) async throws {
        try await engine.approveRegisteredPhoto(book)
        preparedCount = await engine.indexedCount()
    }
    func saveManualCrop(_ book: Book, imageData: Data, source: String, rect: CGRect) async throws {
        try await engine.saveManualCrop(book, imageData: imageData, source: source, rect: rect)
        preparedCount = await engine.indexedCount()
    }
    #if DEBUG
        func inspectRegistration(_ book: Book) async throws -> CoverRegistrationInspection {
            try await engine.inspectRegistration(book)
        }
    #endif
}

#if DEBUG
struct CoverRegistrationInspection: Sendable {
    let sourceImage: Data
    let originalModelInput: Data
    let rectifiedImage: Data?
    let rectifiedModelInput: Data?
    let originalSimilarity: Float?
    let rectifiedSimilarity: Float?
    let sourceMatchesIndex: Bool
    let isRemote: Bool
    let sourceIdentity: String
    let manualRect: CGRect?
}
#endif
