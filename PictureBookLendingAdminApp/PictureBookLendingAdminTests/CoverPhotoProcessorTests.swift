import Foundation
import Testing
import UIKit

@testable import PictureBookLendingAdmin

@Suite("撮影した表紙の確認・調整")
struct CoverPhotoProcessorTests {
    @Test("交差・画像外・極小の四隅を拒否する")
    func cornerValidation() {
        #expect(CoverPhotoCorners.fullImage.isValid)
        var crossing = CoverPhotoCorners.fullImage
        crossing.points.swapAt(1, 2)
        #expect(!crossing.isValid)
        let outside = CoverPhotoCorners(points: [
            CGPoint(x: -0.1, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 1, y: 1), CGPoint(x: 0, y: 1),
        ])
        #expect(!outside.isValid)
        #expect(CoverPhotoCorners.fullImage.moving(0, to: CGPoint(x: 1, y: 1)) == .fullImage)
    }

    @Test("縦長の表紙を正方形にせず、指定範囲だけ切り抜く")
    @MainActor func renderManualCrop() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let original = UIGraphicsImageRenderer(
            size: CGSize(width: 400, height: 600), format: format
        ).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 600))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 100, y: 100, width: 200, height: 400))
        }
        let source = try CoverPhotoProcessor.normalizedData(original)
        let corners = CoverPhotoCorners(points: [
            CGPoint(x: 0.25, y: 1.0 / 6), CGPoint(x: 0.75, y: 1.0 / 6),
            CGPoint(x: 0.75, y: 5.0 / 6), CGPoint(x: 0.25, y: 5.0 / 6),
        ])
        let result = try await CoverPhotoProcessor.shared.render(source, corners: corners)
        let cropped = try #require(UIImage(data: result)?.cgImage)
        #expect(abs(cropped.width - 200) <= 2)
        #expect(abs(cropped.height - 400) <= 2)
        // A small sample near the corner must be blue, not the surrounding red desk.
        let pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
        defer { pixels.deallocate() }
        let context = try #require(
            CGContext(
                data: pixels, width: 1, height: 1, bitsPerComponent: 8,
                bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        let sample = try #require(cropped.cropping(to: CGRect(x: 10, y: 10, width: 5, height: 5)))
        context.draw(sample, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        #expect(pixels[2] > 200 && pixels[0] < 40)
    }

    @Test("写真の向きを表示と処理で統一する")
    @MainActor func orientationNormalization() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let source = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 500), format: format)
            .image { context in
                UIColor.blue.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 300, height: 500))
            }
        let rotated = UIImage(cgImage: try #require(source.cgImage), scale: 1, orientation: .right)
        let normalized = try #require(UIImage(data: CoverPhotoProcessor.normalizedData(rotated)))
        #expect(normalized.imageOrientation == .up)
        #expect(normalized.size.width > normalized.size.height)
    }

    @Test(
        "自動検出は回転・反転後の表示座標に一致し、その後も手動調整できる",
        arguments: [
            UIImage.Orientation.up, .down, .left, .right,
            .upMirrored, .downMirrored, .leftMirrored, .rightMirrored,
        ])
    @MainActor func detectAndReadjust(orientation: UIImage.Orientation) async throws {
        // Original geometric artwork, deliberately off-center to expose flipped coordinates.
        let original = syntheticPhoto(hasCover: true)
        let oriented = UIImage(
            cgImage: try #require(original.cgImage), scale: 1, orientation: orientation)
        let data = try CoverPhotoProcessor.normalizedData(oriented)
        let proposal = try await CoverPhotoProcessor.shared.propose(data)
        #expect(proposal.detected)
        let expected: CGRect
        switch orientation {
        case .up: expected = CGRect(x: 0.12, y: 0.18, width: 0.56, height: 0.62)
        case .down: expected = CGRect(x: 0.32, y: 0.20, width: 0.56, height: 0.62)
        case .left: expected = CGRect(x: 0.18, y: 0.32, width: 0.62, height: 0.56)
        case .right: expected = CGRect(x: 0.20, y: 0.12, width: 0.62, height: 0.56)
        case .upMirrored: expected = CGRect(x: 0.32, y: 0.18, width: 0.56, height: 0.62)
        case .downMirrored: expected = CGRect(x: 0.12, y: 0.20, width: 0.56, height: 0.62)
        case .leftMirrored: expected = CGRect(x: 0.18, y: 0.12, width: 0.62, height: 0.56)
        case .rightMirrored: expected = CGRect(x: 0.20, y: 0.32, width: 0.62, height: 0.56)
        @unknown default: throw CoverRecognitionError.invalidImage
        }
        let expectedPoints = [
            CGPoint(x: expected.minX, y: expected.minY),
            CGPoint(x: expected.maxX, y: expected.minY),
            CGPoint(x: expected.maxX, y: expected.maxY),
            CGPoint(x: expected.minX, y: expected.maxY),
        ]
        for (actual, expected) in zip(proposal.corners.points, expectedPoints) {
            #expect(abs(actual.x - expected.x) < 0.02)
            #expect(abs(actual.y - expected.y) < 0.02)
        }
        let topLeft = proposal.corners.points[0]
        let adjusted = proposal.corners.moving(
            0, to: CGPoint(x: topLeft.x + 0.03, y: topLeft.y + 0.03))
        #expect(adjusted != proposal.corners)
        #expect(adjusted.isValid)
        let rendered = try await CoverPhotoProcessor.shared.render(data, corners: adjusted)
        #expect(UIImage(data: rendered) != nil)
    }

    @Test("単色画像は未検出として返す")
    @MainActor func noRectangle() async throws {
        let data = try CoverPhotoProcessor.normalizedData(syntheticPhoto(hasCover: false))
        let proposal = try await CoverPhotoProcessor.shared.propose(data)
        #expect(!proposal.detected)
        #expect(proposal.corners == .fullImage)
    }

    @Test("キャンセル済みの検出は結果を返さない")
    func cancelledDetection() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            do {
                _ = try await CoverPhotoProcessor.shared.propose(Data())
                Issue.record("Cancelled detection returned a result")
            } catch is CancellationError {
                // Cancellation is checked before decoding or running Vision.
            } catch {
                Issue.record("Expected cancellation, got \(error)")
            }
        }
        await task.value
    }

    @MainActor private func syntheticPhoto(hasCover: Bool) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 800, height: 1000), format: format)
            .image { context in
                UIColor.black.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 800, height: 1000))
                if hasCover {
                    UIColor.white.setFill()
                    context.fill(CGRect(x: 96, y: 180, width: 448, height: 620))
                }
            }
    }
}
