import CoreImage
import UIKit
import XCTest

@testable import PictureBookLendingAdmin

final class LiveCoverFrameProcessorTests: XCTestCase {
    private func rectangle(_ rect: CGRect) -> CoverPhotoCorners {
        CoverPhotoCorners(points: [
            CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY),
        ])
    }

    func testAspectFillGuideMatchesCropAcrossSizesAndUprightRotations() throws {
        for preview in [
            CGSize(width: 390, height: 420), CGSize(width: 744, height: 600),
            CGSize(width: 900, height: 500), CGSize(width: 320, height: 120),
        ] {
            // Buffers are already rotated by AVCapture. 0/180 share dimensions, as do 90/270.
            for image in [CGSize(width: 1080, height: 1920), CGSize(width: 1920, height: 1080)] {
                let geometry = LiveCoverGeometry(size: preview)
                let crop = try XCTUnwrap(geometry.cropRect(imageSize: image))
                let scale = max(preview.width / image.width, preview.height / image.height)
                for (point, expected) in zip(
                    CoverPhotoCorners.fullImage.points, rectangle(geometry.guide).points)
                {
                    let actual = geometry.previewPoint(point, crop: crop, imageSize: image)
                    XCTAssertEqual(actual.x, expected.x, accuracy: scale)
                    XCTAssertEqual(actual.y, expected.y, accuracy: scale)
                    XCTAssertTrue(
                        geometry.guide.contains(actual) || actual.x == geometry.guide.maxX
                            || actual.y == geometry.guide.maxY)
                }
                XCTAssertTrue(CGRect(origin: .zero, size: image).contains(crop))
            }
        }
        XCTAssertNil(
            LiveCoverGeometry(size: .zero).cropRect(imageSize: CGSize(width: 100, height: 100)))
    }

    func testOutsidePatternCannotChangeQueryPixels() throws {
        let geometry = LiveCoverGeometry(size: CGSize(width: 320, height: 480))
        let size = CGSize(width: 800, height: 600)
        let crop = try XCTUnwrap(geometry.cropRect(imageSize: size))
        func image(background: UIColor) -> CIImage {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return CIImage(
                cgImage: UIGraphicsImageRenderer(size: size, format: format).image { context in
                    background.setFill()
                    context.fill(CGRect(origin: .zero, size: size))
                    UIColor.gray.setFill()
                    context.fill(crop)
                    UIColor.blue.setFill()
                    context.fill(
                        CGRect(x: crop.midX - 20, y: crop.midY - 20, width: 40, height: 40))
                }.cgImage!)
        }
        var first = LiveCoverFrameProcessor()
        var second = LiveCoverFrameProcessor()
        for _ in 0..<2 {
            let a = try XCTUnwrap(first.process(image(background: .red), geometry: geometry))
            let b = try XCTUnwrap(second.process(image(background: .green), geometry: geometry))
            XCTAssertEqual(
                try a.image.encodedData(type: "public.png"),
                try b.image.encodedData(type: "public.png"))
        }
    }

    func testStabilityRequiresConsecutiveNearbyCornersAndResetsOnLoss() {
        var stability = LiveCoverStability()
        let cover = rectangle(CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8))
        XCTAssertFalse(stability.accept(cover))
        XCTAssertTrue(stability.accept(cover))
        XCTAssertFalse(stability.accept(nil))
        XCTAssertFalse(stability.accept(cover))
        XCTAssertFalse(stability.accept(rectangle(CGRect(x: 0.2, y: 0.1, width: 0.7, height: 0.8))))
    }

    func testSelectsLargeCentralCoverInsteadOfInnerArtworkOrOffCenterObject() {
        let cover = rectangle(CGRect(x: 0.15, y: 0.1, width: 0.7, height: 0.8))
        let artwork = rectangle(CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4))
        let edge = rectangle(CGRect(x: 0, y: 0.1, width: 0.3, height: 0.8))
        XCTAssertEqual(LiveCoverFrameProcessor.select([artwork, edge, cover]), cover)
        XCTAssertNil(LiveCoverFrameProcessor.select([artwork, edge]))
        for rect in [
            CGRect(x: 0.1, y: 0.2, width: 0.8, height: 0.6),
            CGRect(x: 0.2, y: 0.1, width: 0.6, height: 0.8),
            CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7),
        ] {
            XCTAssertEqual(LiveCoverFrameProcessor.select([rectangle(rect)]), rectangle(rect))
        }
    }

    private enum Fixture { case shirt, occluded, tilted }

    /// Original geometric fixtures: no library/private photographs or external requests.
    private func fixture(_ kind: Fixture) -> CIImage {
        let size = CGSize(width: 600, height: 600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return CIImage(
            cgImage: UIGraphicsImageRenderer(size: size, format: format).image { context in
                UIColor.darkGray.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                if kind == .shirt {
                    UIColor.blue.setFill()
                    let shirt = UIBezierPath()
                    shirt.move(to: CGPoint(x: 150, y: 160))
                    for p in [
                        CGPoint(x: 240, y: 120), CGPoint(x: 300, y: 160), CGPoint(x: 360, y: 120),
                        CGPoint(x: 450, y: 160), CGPoint(x: 550, y: 300), CGPoint(x: 440, y: 340),
                        CGPoint(x: 420, y: 580), CGPoint(x: 180, y: 580), CGPoint(x: 160, y: 340),
                        CGPoint(x: 50, y: 300),
                    ] { shirt.addLine(to: p) }
                    shirt.close()
                    shirt.fill()
                } else {
                    UIColor.white.setFill()
                    let cover = UIBezierPath()
                    cover.move(to: CGPoint(x: 150, y: 100))
                    cover.addLine(to: CGPoint(x: 470, y: 145))
                    cover.addLine(to: CGPoint(x: 430, y: 510))
                    cover.addLine(to: CGPoint(x: 130, y: 470))
                    cover.close()
                    cover.fill()
                    UIColor.orange.setFill()
                    UIBezierPath(ovalIn: CGRect(x: 240, y: 220, width: 110, height: 140)).fill()
                    if kind == .occluded {
                        // Broad curved hand-like occluders remove all four corners.
                        UIColor.brown.setFill()
                        for p in [
                            CGPoint(x: 150, y: 100), CGPoint(x: 470, y: 145),
                            CGPoint(x: 430, y: 510), CGPoint(x: 130, y: 470),
                        ] {
                            UIBezierPath(
                                ovalIn: CGRect(x: p.x - 85, y: p.y - 85, width: 170, height: 170)
                            ).fill()
                        }
                    }
                }
            }.cgImage!)
    }

    func testShirtAndOccludedCoverContinueSearchingWithoutCorners() throws {
        let geometry = LiveCoverGeometry(size: CGSize(width: 600, height: 600))
        for kind in [Fixture.shirt, .occluded] {
            var processor = LiveCoverFrameProcessor()
            for _ in 0..<3 {
                let result = try XCTUnwrap(processor.process(fixture(kind), geometry: geometry))
                XCTAssertNil(result.outline)
                XCTAssertFalse(result.isCorrected)
                XCTAssertEqual(result.image.width, 552)
                XCTAssertEqual(result.image.height, 552)
                XCTAssertFalse(
                    try result.image.encodedData(type: "public.jpeg", quality: 0.9).isEmpty)
            }
        }
    }

    func testTiltedCoverUsesSameDetectedCornersThenResetsAfterLoss() throws {
        let geometry = LiveCoverGeometry(size: CGSize(width: 600, height: 600))
        var processor = LiveCoverFrameProcessor()
        let first = try XCTUnwrap(processor.process(fixture(.tilted), geometry: geometry))
        XCTAssertNotNil(first.outline)
        XCTAssertFalse(first.isCorrected)
        let stable = try XCTUnwrap(processor.process(fixture(.tilted), geometry: geometry))
        XCTAssertTrue(stable.isCorrected)
        XCTAssertEqual(first.outline, stable.outline)
        XCTAssertLessThan(stable.image.width, first.image.width)
        let lost = try XCTUnwrap(processor.process(fixture(.shirt), geometry: geometry))
        XCTAssertNil(lost.outline)
        XCTAssertFalse(lost.isCorrected)
        XCTAssertFalse(
            try XCTUnwrap(processor.process(fixture(.tilted), geometry: geometry)).isCorrected)
        processor.reset()
        XCTAssertFalse(
            try XCTUnwrap(processor.process(fixture(.tilted), geometry: geometry)).isCorrected)
    }
}
