import CoreImage
import Foundation
import Vision

/// Geometry is in the upright, unmirrored preview/output coordinate system.
/// Inverting aspect-fill here avoids applying raw metadata coordinates to rotated buffers.
struct LiveCoverGeometry: Equatable, Sendable {
    static let guideInset: CGFloat = 24
    let size: CGSize

    var guide: CGRect {
        CGRect(origin: .zero, size: size).insetBy(dx: Self.guideInset, dy: Self.guideInset)
    }

    func cropRect(imageSize: CGSize) -> CGRect? {
        guard size.width > 2 * Self.guideInset, size.height > 2 * Self.guideInset,
            imageSize.width > 0, imageSize.height > 0
        else { return nil }
        let scale = max(size.width / imageSize.width, size.height / imageSize.height)
        let offset = CGPoint(
            x: (imageSize.width * scale - size.width) / 2,
            y: (imageSize.height * scale - size.height) / 2)
        // Round inward so not even an edge pixel outside the guide enters recognition.
        let left = ceil((guide.minX + offset.x) / scale)
        let top = ceil((guide.minY + offset.y) / scale)
        let right = floor((guide.maxX + offset.x) / scale)
        let bottom = floor((guide.maxY + offset.y) / scale)
        guard right > left, bottom > top else { return nil }
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    func previewPoint(_ point: CGPoint, crop: CGRect, imageSize: CGSize) -> CGPoint {
        let scale = max(size.width / imageSize.width, size.height / imageSize.height)
        return CGPoint(
            x: (crop.minX + point.x * crop.width) * scale
                - (imageSize.width * scale - size.width) / 2,
            y: (crop.minY + point.y * crop.height) * scale
                - (imageSize.height * scale - size.height) / 2)
    }
}

struct LiveCoverStability {
    private var previous: CoverPhotoCorners?
    private static let tolerance: CGFloat = 0.035

    mutating func accept(_ corners: CoverPhotoCorners?) -> Bool {
        defer { previous = corners }
        guard let corners, let previous else { return false }
        return zip(corners.points, previous.points).allSatisfy {
            hypot($0.x - $1.x, $0.y - $1.y) <= Self.tolerance
        }
    }
}

/// Only ROI pixels reach Vision and encoding. Failure to detect/correct retains the ROI.
/// Confined to the camera queue; no photographs or features leave the device.
struct LiveCoverFrameProcessor {
    private let context = CIContext()
    private var stability = LiveCoverStability()
    private static let maximumDimension: CGFloat = 1024

    struct Result {
        let image: CGImage
        let outline: CoverPhotoCorners?
        let isCorrected: Bool
        let crop: CGRect
    }

    mutating func reset() { stability = LiveCoverStability() }

    func croppedImage(_ image: CIImage, geometry: LiveCoverGeometry) -> (CGImage, CGRect)? {
        guard let crop = geometry.cropRect(imageSize: image.extent.size) else { return nil }
        let ciRect = CGRect(
            x: image.extent.minX + crop.minX,
            y: image.extent.maxY - crop.maxY, width: crop.width, height: crop.height)
        // Materialize the crop BEFORE resampling, so interpolation cannot sample the background.
        guard let cropped = context.createCGImage(image.cropped(to: ciRect), from: ciRect) else {
            return nil
        }
        return (cropped, crop)
    }

    mutating func process(_ image: CIImage, geometry: LiveCoverGeometry) -> Result? {
        guard let (cropped, crop) = croppedImage(image, geometry: geometry) else { return nil }
        let roi = CIImage(cgImage: cropped)
        let scale = min(1, Self.maximumDimension / max(roi.extent.width, roi.extent.height))
        let resized = roi.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let source = context.createCGImage(resized, from: resized.extent) else { return nil }
        let corners = detect(in: source)
        let stable = stability.accept(corners)
        let corrected = stable ? corners.flatMap { correct(source, corners: $0) } : nil
        return Result(
            image: corrected ?? source, outline: corners, isCorrected: corrected != nil, crop: crop)
    }

    static func select(_ rectangles: [CoverPhotoCorners]) -> CoverPhotoCorners? {
        rectangles.filter { corners in
            guard corners.isValid else { return false }
            let center = corners.points.reduce(CGPoint.zero) {
                CGPoint(x: $0.x + $1.x / 4, y: $0.y + $1.y / 4)
            }
            return area(corners) >= 0.18 && hypot(center.x - 0.5, center.y - 0.5) <= 0.22
        }.max { area($0) < area($1) }
    }

    private static func area(_ corners: CoverPhotoCorners) -> CGFloat {
        (0..<4).reduce(CGFloat.zero) { total, i in
            let a = corners.points[i]
            let b = corners.points[(i + 1) % 4]
            return total + a.x * b.y - b.x * a.y
        } / 2
    }

    private func detect(in image: CGImage) -> CoverPhotoCorners? {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 6
        request.minimumConfidence = 0.8
        request.minimumSize = 0.25
        request.minimumAspectRatio = 0.35
        request.maximumAspectRatio = 1
        guard (try? VNImageRequestHandler(cgImage: image).perform([request])) != nil else {
            return nil
        }
        return Self.select(
            (request.results ?? []).map { rectangle in
                CoverPhotoCorners(
                    points: [
                        rectangle.topLeft, rectangle.topRight, rectangle.bottomRight,
                        rectangle.bottomLeft,
                    ].map {
                        CGPoint(x: $0.x, y: 1 - $0.y)
                    })
            })
    }

    private func correct(_ image: CGImage, corners: CoverPhotoCorners) -> CGImage? {
        let source = CIImage(cgImage: image)
        let keys = ["inputTopLeft", "inputTopRight", "inputBottomRight", "inputBottomLeft"]
        var parameters: [String: Any] = [:]
        for (key, point) in zip(keys, corners.points) {
            parameters[key] = CIVector(
                x: point.x * source.extent.width, y: (1 - point.y) * source.extent.height)
        }
        let corrected = source.applyingFilter("CIPerspectiveCorrection", parameters: parameters)
        return context.createCGImage(corrected, from: corrected.extent)
    }
}
