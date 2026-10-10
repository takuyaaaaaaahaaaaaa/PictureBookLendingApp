import CoreImage
import Foundation
import ImageIO
import UIKit
import Vision

/// Normalized image coordinates, origin at the upper left; ordered around the cover.
struct CoverPhotoCorners: Equatable, Sendable {
    var points: [CGPoint]
    static let fullImage = CoverPhotoCorners(points: [
        CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0),
        CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1),
    ])
    var isValid: Bool {
        guard points.count == 4,
            points.allSatisfy({
                $0.x.isFinite && $0.y.isFinite && (0...1).contains($0.x) && (0...1).contains($0.y)
            })
        else { return false }
        var area: CGFloat = 0
        for i in 0..<4 {
            let a = points[i]
            let b = points[(i + 1) % 4]
            let c = points[(i + 2) % 4]
            guard (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x) > 0.0001 else {
                return false
            }
            area += a.x * b.y - b.x * a.y
        }
        return area / 2 >= 0.02
    }
    func moving(_ corner: Int, to point: CGPoint) -> Self {
        var changed = self
        changed.points[corner] = CGPoint(x: min(1, max(0, point.x)), y: min(1, max(0, point.y)))
        return changed.isValid ? changed : self
    }
}
struct CoverPhotoProposal: Sendable {
    let corners: CoverPhotoCorners
    let detected: Bool
    let previewData: Data
}
actor CoverPhotoProcessor {
    static let shared = CoverPhotoProcessor()
    private let context = CIContext()

    /// Apply UIImage orientation once, before displaying or detecting the cover.
    @MainActor static func normalizedData(_ image: UIImage) throws -> Data {
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { throw CoverRecognitionError.invalidImage }
        let scale = min(1, 1600 / longest)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let upright = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = upright.pngData() else { throw CoverRecognitionError.invalidImage }
        return data
    }
    private func image(_ data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw CoverRecognitionError.invalidImage
        }
        return image
    }
    func propose(_ data: Data) throws -> CoverPhotoProposal {
        try Task.checkCancellation()
        let source = try image(data)
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 6
        request.minimumConfidence = 0.8
        request.minimumSize = 0.15
        request.minimumAspectRatio = 0.25
        request.maximumAspectRatio = 1
        try? VNImageRequestHandler(cgImage: source).perform([request])
        try Task.checkCancellation()
        let rectangle = request.results?
            .filter { $0.boundingBox.width * $0.boundingBox.height >= 0.1 }
            .max {
                $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width
                    * $1.boundingBox.height
            }
        let detected =
            rectangle
            .map { r in
                CoverPhotoCorners(
                    points: [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft].map {
                        CGPoint(x: $0.x, y: 1 - $0.y)
                    })
            }
            .flatMap { $0.isValid ? $0 : nil }
        let corners = detected ?? .fullImage
        return try CoverPhotoProposal(
            corners: corners, detected: detected != nil,
            previewData: render(data, corners: corners))
    }
    func render(_ data: Data, corners: CoverPhotoCorners) throws -> Data {
        guard corners.isValid else { throw CoverRecognitionError.invalidImage }
        let source = CIImage(cgImage: try image(data))
        let extent = source.extent
        let keys = ["inputTopLeft", "inputTopRight", "inputBottomRight", "inputBottomLeft"]
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            throw CoverRecognitionError.invalidImage
        }
        filter.setValue(source, forKey: kCIInputImageKey)
        for (key, point) in zip(keys, corners.points) {
            filter.setValue(
                CIVector(
                    x: extent.minX + point.x * extent.width,
                    y: extent.minY + (1 - point.y) * extent.height), forKey: key)
        }
        guard let corrected = filter.outputImage,
            let result = context.createCGImage(corrected, from: corrected.extent)
        else {
            throw CoverRecognitionError.invalidImage
        }
        return try result.encodedData(type: "public.jpeg", quality: 0.95)
    }
}

extension CGImage {
    /// Encodes with ImageIO; `type` is a UTI such as "public.jpeg" or "public.png".
    func encodedData(type: String, quality: CGFloat? = nil) throws -> Data {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, type as CFString, 1, nil)
        else {
            throw CoverRecognitionError.invalidImage
        }
        let options = quality.map {
            [kCGImageDestinationLossyCompressionQuality: $0] as CFDictionary
        }
        CGImageDestinationAddImage(destination, self, options)
        guard CGImageDestinationFinalize(destination) else {
            throw CoverRecognitionError.invalidImage
        }
        return output as Data
    }
}
