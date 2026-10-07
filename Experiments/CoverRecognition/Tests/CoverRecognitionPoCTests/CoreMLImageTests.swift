import CoreML
import Foundation
import Testing
@testable import CoverRecognitionPoC

@Test func fastViTImageToLocalCandidates() throws {
    let modelURL = try #require(Bundle.module.url(forResource: "FastViTT8F16Headless", withExtension: "mlpackage"))
    let encoder = try CoreMLCoverEncoder(modelURL: modelURL)
    let registered = try encoder.encode(makeImage(red: true, shifted: false))
    let separateQuery = try encoder.encode(makeImage(red: true, shifted: true))
    let other = try encoder.encode(makeImage(red: false, shifted: false))
    #expect(registered.count == 768)
    #expect(registered.allSatisfy { $0.isFinite })
    var index = CoverIndex(encoderVersion: CoreMLCoverEncoder.version)
    let target = UUID(), distractor = UUID()
    try index.add(registered, for: target)
    try index.add(other, for: distractor)
    let result = try index.search(separateQuery, minimumSimilarity: -1)
    #expect(result.candidates.first?.bookID == target)
    #expect(try index.search(other, minimumSimilarity: 1.1).needsManualSearch)
    print("FastViT scores:", result.candidates.map(\.similarity))
}
