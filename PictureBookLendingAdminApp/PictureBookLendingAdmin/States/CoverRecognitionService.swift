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
enum CoverSearchPolicy {
    static let minimumSimilarity: Float = 0.70
    static let maximumCandidates = 5

    static func candidates(from matches: [CoverMatch]) -> [CoverMatch] {
        Array(matches.filter { $0.similarity >= minimumSimilarity }
            .sorted { $0.similarity > $1.similarity }.prefix(maximumCandidates))
    }
}

struct CoverMatch: Identifiable, Sendable {
    let id: UUID
    let similarity: Float
}
enum CoverRecognitionError: LocalizedError {
    case modelUnavailable
    case invalidImage
    case invalidFeatures
    case unreadablePreparation
    case cleanupFailed
    case catalogIncomplete
    var errorDescription: String? {
        switch self {
        case .modelUnavailable: "表紙検索モデルを読み込めませんでした"
        case .invalidImage: "画像を読み込めませんでした"
        case .invalidFeatures: "表紙の特徴を取得できませんでした"
        case .unreadablePreparation: "表紙の調整情報を読み込めませんでした。バックアップからの復元が必要です。"
        case .cleanupFailed: "表紙検索データの削除に失敗しました。設定から検索準備を再試行してください。"
        case .catalogIncomplete: "図書一覧を読み込めないため、表紙検索データを整理できませんでした。アプリを開き直して再試行してください。"
        }
    }
}
private struct ManualCoverCrop: Codable {
    let id: UUID
    let source: String
    var imageData: Data?  // Legacy inline snapshot, migrated on first actor access.
    let rect: CGRect
}

private struct CoverPreparationArchive: Codable {
    static let currentVersion = 1
    let version: Int
    let crops: [UUID: ManualCoverCrop]
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
    private var unreadableCrops = false
    private var catalogRevision = 0
    private let cropImagesURL: URL
    private let session: URLSession
    private let deleteFile: @Sendable (URL) throws -> Void
    private var index = CoverFeatureIndex()
    private var model: MLModel?
    init(indexURL: URL? = nil, session: URLSession = .shared,
         deleteFile: @escaping @Sendable (URL) throws -> Void = { try FileManager.default.removeItem(at: $0) }) {
        self.deleteFile = deleteFile
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
        do {
            crops = try JSONDecoder().decode([UUID: ManualCoverCrop].self, from: Data(contentsOf: cropsURL))
        } catch CocoaError.fileReadNoSuchFile {
            crops = [:]
        } catch {
            unreadableCrops = true
        }
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
        guard !unreadableCrops || ids.isEmpty else { throw CoverRecognitionError.unreadablePreparation }
        catalogRevision += 1
        let previousIndex = index.entries
        index.entries = index.entries.filter { ids.contains($0.key) }
        do { try save() } catch { index.entries = previousIndex; throw error }
        let previousCrops = crops
        crops = crops.filter { ids.contains($0.key) }
        do { try saveCrops(replacingUnreadable: ids.isEmpty) } catch { crops = previousCrops; throw error }
        // Also retry orphan cleanup after an earlier partial deletion.
        let retained = Set(crops.values.map { cropImageURL($0).lastPathComponent })
        let files: [URL]
        do { files = try FileManager.default.contentsOfDirectory(at: cropImagesURL, includingPropertiesForKeys: nil) }
        catch CocoaError.fileReadNoSuchFile { return }
        var failure: Error?
        for url in files where !retained.contains(url.lastPathComponent) {
            do { try deleteFile(url) } catch { failure = error }
        }
        if let failure { throw failure }
    }
    func remove(bookID: UUID) throws {
        loadIfNeeded()
        guard !unreadableCrops else { throw CoverRecognitionError.unreadablePreparation }
        guard index.entries[bookID] != nil || crops[bookID] != nil else { return }
        let retained = Set(index.entries.keys).union(crops.keys).subtracting([bookID])
        try removeBooks(notIn: retained)
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
        let revision = catalogRevision
        guard let data = try await originalImageData(for: book, source: source) else { return false }
        // Catalog replacement or deletion must win over a suspended old download.
        guard revision == catalogRevision, !Task.isCancelled else { return false }
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
        // Similarity is a trial threshold, not calibrated confidence.
        CoverSearchPolicy.candidates(from:
            try scoredMatches(imageData: imageData, validBookIDs: validBookIDs, detectCover: detectCover))
    }
    private func scoredMatches(
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
    private func saveCrops(replacingUnreadable: Bool = false) throws {
        guard !unreadableCrops || replacingUnreadable else { throw CoverRecognitionError.unreadablePreparation }
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
        unreadableCrops = false
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
    /// Transfer user-selected preparation, not regenerable feature vectors.
    func exportPreparation(books: [Book], bookImages: [String: Data]) throws -> Data {
        loadIfNeeded()
        guard !unreadableCrops else { throw CoverRecognitionError.unreadablePreparation }
        var exported: [UUID: ManualCoverCrop] = [:]
        for book in books {
            guard let crop = crops[book.id], crop.source == imageSource(for: book) else { continue }
            // Export only the crop corresponding to the image in this exact snapshot.
            if let fileName = book.localImageFileName {
                guard let archivedImage = bookImages[fileName],
                    ImageStorageUtility.readImageData(fileName: fileName) == archivedImage else { continue }
            }
            var snapshot = crop
            snapshot.imageData = try cropData(crop)
            exported[book.id] = snapshot
        }
        return try JSONEncoder().encode(CoverPreparationArchive(version: CoverPreparationArchive.currentVersion, crops: exported))
    }
    private func decodedPreparation(_ data: Data?) throws -> [UUID: ManualCoverCrop] {
        guard let data else { return [:] }
        let archive = try JSONDecoder().decode(CoverPreparationArchive.self, from: data)
        guard archive.version == CoverPreparationArchive.currentVersion else { throw CoverRecognitionError.invalidImage }
        for crop in archive.crops.values {
            guard let pixels = crop.imageData else { throw CoverRecognitionError.invalidImage }
            _ = try croppedImage(try decodedImage(pixels), rect: crop.rect)
        }
        return archive.crops
    }
    func validatePreparation(_ data: Data?) throws { _ = try decodedPreparation(data) }
    func restorePreparation(_ data: Data?, books: [Book]) throws {
        let restored = try decodedPreparation(data)
        loadIfNeeded()
        var replacement: [UUID: ManualCoverCrop] = [:]
        for book in books {
            guard let crop = restored[book.id], let source = imageSource(for: book) else { continue }
            let sourceMatches: Bool
            if let fileName = book.localImageFileName {
                sourceMatches = crop.source.hasPrefix("local:\(fileName):")
            } else {
                sourceMatches = crop.source == source
            }
            guard sourceMatches else { continue }
            // Restored files have new modification times, while their approved pixels remain unchanged.
            replacement[book.id] = ManualCoverCrop(id: UUID(), source: source,
                imageData: crop.imageData, rect: crop.rect)
        }
        catalogRevision += 1
        let previousIndex = index
        index = CoverFeatureIndex()
        do { try save() } catch { index = previousIndex; throw error }
        let previous = crops
        crops = replacement
        do { try saveCrops(replacingUnreadable: true) } catch {
            crops = previous
            for crop in replacement.values { try? FileManager.default.removeItem(at: cropImageURL(crop)) }
            throw error
        }
        for crop in previous.values { try? FileManager.default.removeItem(at: cropImageURL(crop)) }
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
    @ObservationIgnored private var preparationGeneration = 0
    @ObservationIgnored private var requestRevision = 0
    private(set) var preparedCount = 0
    private(set) var pendingCount = 0
    private(set) var isPreparing = false
    private(set) var preparationError: String?
    /// Safe to invoke again after app restart, restore, image replacement, or a failed download.
    func prepare(books: [Book], isComplete: Bool) async {
        guard isComplete else { return }
        requestRevision += 1
        guard !isPreparing else {
            queuedBooks = books
            return
        }
        isPreparing = true
        let generation = preparationGeneration
        defer {
            finishPreparation(generation: generation)
        }
        preparationError = nil
        do { try await engine.removeBooks(notIn: Set(books.map(\.id))) }
        catch {
            guard generation == preparationGeneration else { return }
            preparationError = ((error as? CoverRecognitionError) ?? .cleanupFailed).localizedDescription
            return
        }
        guard generation == preparationGeneration else { return }
        preparedCount = 0
        pendingCount = 0
        for book in books {
            if Task.isCancelled { break }
            let indexed = (try? await engine.indexIfNeeded(book)) ?? false
            guard generation == preparationGeneration else { return }
            if indexed { preparedCount += 1 } else { pendingCount += 1 }
        }
    }
    private func finishPreparation(generation: Int) {
        guard generation == preparationGeneration else { return }
        isPreparing = false
        if let books = queuedBooks {
            queuedBooks = nil
            let revision = requestRevision
            Task {
                guard self.requestRevision == revision else { return }
                await self.prepare(books: books, isComplete: true)
            }
        }
    }
    /// Explicit deletion must report cleanup failure instead of completing optimistically.
    func removeDeletedBooks(books: [Book], isComplete: Bool) async throws {
        guard isComplete else { throw CoverRecognitionError.catalogIncomplete }
        preparationGeneration += 1
        requestRevision += 1
        let generation = preparationGeneration
        queuedBooks = nil
        isPreparing = true
        defer { finishPreparation(generation: generation) }
        do {
            try await engine.removeBooks(notIn: Set(books.map(\.id)))
            guard generation == preparationGeneration else { return }
            let count = await engine.indexedCount()
            guard generation == preparationGeneration else { return }
            preparedCount = count
            preparationError = nil
            // Resume remaining books whose preparation was interrupted by deletion.
            if queuedBooks == nil { queuedBooks = books }
        } catch {
            let failure = (error as? CoverRecognitionError) ?? .cleanupFailed
            preparationError = failure.localizedDescription
            throw failure
        }
    }
    func exportPreparation(books: [Book], bookImages: [String: Data]) async throws -> Data {
        try await engine.exportPreparation(books: books, bookImages: bookImages)
    }
    func validatePreparation(_ data: Data?) async throws {
        try await engine.validatePreparation(data)
    }
    func restorePreparation(_ data: Data?, books: [Book], isComplete: Bool) async throws {
        guard isComplete else { throw CoverRecognitionError.catalogIncomplete }
        preparationGeneration += 1
        requestRevision += 1
        let generation = preparationGeneration
        queuedBooks = nil
        isPreparing = true
        defer { finishPreparation(generation: generation) }
        try await engine.restorePreparation(data, books: books)
        guard generation == preparationGeneration else { return }
        if queuedBooks == nil { queuedBooks = books }
    }
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
