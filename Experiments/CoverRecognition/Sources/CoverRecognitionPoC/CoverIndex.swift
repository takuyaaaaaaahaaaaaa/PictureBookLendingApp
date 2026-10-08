import Foundation
import Vision
import CoreGraphics

/// Vision's bundled image feature print is a fixed model. Adding a book stores a vector;
/// it does not train or update the neural network's weights.
public struct VisionCoverEncoder {
    public static let version = "VNGenerateImageFeaturePrintRequest-revision-1-centerCrop-v1"

    public init() {}

    public func encode(_ image: CGImage) throws -> [Float] {
        let request = VNGenerateImageFeaturePrintRequest()
        request.revision = VNGenerateImageFeaturePrintRequestRevision1
        request.imageCropAndScaleOption = .centerCrop
        try VNImageRequestHandler(cgImage: image).perform([request])
        guard let observation = request.results?.first,
              observation.elementType == .float,
              observation.data.count == observation.elementCount * MemoryLayout<Float>.size else {
            throw CoverIndexError.invalidFeaturePrint
        }
        return observation.data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
    }
}

public enum CoverIndexError: Error, Equatable {
    case invalidFeaturePrint
    case invalidVector
    case versionMismatch
}

public struct CoverCandidate: Equatable {
    public let bookID: UUID
    /// Cosine similarity. A score is for ranking, not a calibrated probability.
    public let similarity: Float
}

public struct CoverSearchResult {
    public let candidates: [CoverCandidate]
    /// Always requires a person to select a book. Empty when the best score is too low.
    public let needsManualSearch: Bool
}

/// One or more cover examples may belong to a book; multiple physical copies share a cover.
/// A catalogue change should explicitly remove stale book IDs and add new images.
public struct CoverIndex: Codable {
    public let encoderVersion: String
    private var samples: [UUID: [[Float]]] = [:]

    public init(encoderVersion: String = VisionCoverEncoder.version) {
        self.encoderVersion = encoderVersion
    }

    public var bookCount: Int { samples.count }

    public mutating func add(_ vector: [Float], for bookID: UUID) throws {
        guard !vector.isEmpty, vector.allSatisfy({ $0.isFinite }),
              (samples.values.first?.first?.count ?? vector.count) == vector.count else {
            throw CoverIndexError.invalidVector
        }
        let magnitude = sqrt(vector.reduce(Float.zero) { $0 + $1 * $1 })
        guard magnitude.isFinite, magnitude > 0 else { throw CoverIndexError.invalidVector }
        samples[bookID, default: []].append(vector.map { $0 / magnitude })
    }

    public mutating func remove(bookID: UUID) { samples.removeValue(forKey: bookID) }

    public func search(_ vector: [Float], limit: Int = 3, minimumSimilarity: Float = 0.75) throws -> CoverSearchResult {
        guard !vector.isEmpty, vector.allSatisfy({ $0.isFinite }),
              (samples.values.first?.first?.count ?? vector.count) == vector.count else {
            throw CoverIndexError.invalidVector
        }
        let magnitude = sqrt(vector.reduce(Float.zero) { $0 + $1 * $1 })
        guard magnitude.isFinite, magnitude > 0 else { throw CoverIndexError.invalidVector }
        let normalized = vector.map { $0 / magnitude }
        let ranked = samples.map { bookID, examples in
            CoverCandidate(bookID: bookID, similarity: examples.map { sample in
                zip(sample, normalized).reduce(Float.zero) { $0 + $1.0 * $1.1 }
            }.max() ?? -1)
        }.sorted { $0.similarity > $1.similarity }
        let candidates = Array(ranked.prefix(max(0, limit)).filter { $0.similarity >= minimumSimilarity })
        return CoverSearchResult(candidates: candidates, needsManualSearch: candidates.isEmpty)
    }

    public func save(to url: URL) throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: url, options: .atomic)
    }

    public static func load(from url: URL, encoderVersion: String = VisionCoverEncoder.version) throws -> Self {
        let index = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        guard index.encoderVersion == encoderVersion else { throw CoverIndexError.versionMismatch }
        return index
    }
}
