import CoreGraphics
import Foundation
import Testing
@testable import CoverRecognitionPoC

@Test func addSearchDeleteReloadAndVersion() throws {
    let first = UUID(), second = UUID()
    var index = CoverIndex()
    try index.add([1, 0, 0], for: first)
    try index.add([0.9, 0.1, 0], for: first)
    try index.add([0, 1, 0], for: second)
    #expect(try index.search([1, 0, 0]).candidates.first?.bookID == first)
    #expect(try index.search([0, 0, 1]).needsManualSearch)

    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    try index.save(to: url)
    var loaded = try CoverIndex.load(from: url)
    #expect(loaded.bookCount == 2)
    #expect(throws: CoverIndexError.versionMismatch) {
        try CoverIndex.load(from: url, encoderVersion: "new-model")
    }
    loaded.remove(bookID: first)
    #expect(loaded.bookCount == 1)
    #expect(try loaded.search([1, 0, 0]).needsManualSearch)
}

@Test func rejectsBadVectors() throws {
    var index = CoverIndex()
    #expect(throws: CoverIndexError.invalidVector) { try index.add([], for: UUID()) }
    #expect(throws: CoverIndexError.invalidVector) { try index.add([.nan, 1], for: UUID()) }
    try index.add([1, 0], for: UUID())
    #expect(throws: CoverIndexError.invalidVector) { try index.add([1, 0, 0], for: UUID()) }
}

@Test func visionProcessesSeparateImageInputs() throws {
    // Deliberately synthetic shapes: verifies the image pipeline, not real-cover accuracy.
    let encoder = VisionCoverEncoder()
    let registered = try encoder.encode(makeImage(red: true, shifted: false))
    let separateQuery = try encoder.encode(makeImage(red: true, shifted: true))
    let other = try encoder.encode(makeImage(red: false, shifted: false))
    #expect(!registered.isEmpty)
    #expect(registered.count == separateQuery.count)
    var index = CoverIndex()
    let target = UUID(), distractor = UUID()
    try index.add(registered, for: target)
    try index.add(other, for: distractor)
    let result = try index.search(separateQuery, minimumSimilarity: -1)
    #expect(result.candidates.first?.bookID == target)
    #expect(try index.search(other, minimumSimilarity: 1.1).needsManualSearch)
}

private func makeImage(red: Bool, shifted: Bool) -> CGImage {
    let width = 256, height = 256
    let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.setFillColor(red
        ? CGColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1)
        : CGColor(red: 0.1, green: 0.2, blue: 0.9, alpha: 1))
    context.fill(CGRect(x: shifted ? 39 : 32, y: 30, width: 170, height: 185))
    context.setFillColor(CGColor(red: 1, green: 0.9, blue: 0.1, alpha: 1))
    context.fillEllipse(in: CGRect(x: shifted ? 100 : 95, y: 85, width: 55, height: 55))
    return context.makeImage()!
}
