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
}
