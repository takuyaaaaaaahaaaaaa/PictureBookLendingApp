import CoreML
import Foundation
import Testing

@Test func coreMLUpdateSaveReloadPredict() throws {
    let modelURL = try #require(Bundle.module.url(forResource: "CoverKNNFixture", withExtension: "mlmodelc"))
    let saved = FileManager.default.temporaryDirectory.appendingPathComponent("knn-\(UUID().uuidString).mlmodelc")
    defer { try? FileManager.default.removeItem(at: saved) }

    func vector(_ values: [Float]) throws -> MLMultiArray {
        let array = try MLMultiArray(shape: [3], dataType: .float32)
        for (index, value) in values.enumerated() { array[index] = NSNumber(value: value) }
        return array
    }
    func sample(_ values: [Float], bookID: String) throws -> MLFeatureProvider {
        try MLDictionaryFeatureProvider(dictionary: [
            "embedding": MLFeatureValue(multiArray: vector(values)),
            "bookID": MLFeatureValue(string: bookID),
        ])
    }
    let batch = MLArrayBatchProvider(array: [
        try sample([1, 0, 0], bookID: "book-a"),
        try sample([0, 1, 0], bookID: "book-b"),
    ])
    let done = DispatchSemaphore(value: 0)
    let task = try MLUpdateTask(forModelAt: modelURL, trainingData: batch) { context in
        try? context.model.write(to: saved)
        done.signal()
    }
    task.resume()
    #expect(done.wait(timeout: .now() + 30) == .success)
    let updated = try MLModel(contentsOf: saved)
    let query = try MLDictionaryFeatureProvider(dictionary: ["embedding": MLFeatureValue(multiArray: vector([0.95, 0.05, 0]))])
    #expect(try updated.prediction(from: query).featureValue(for: "bookID")?.stringValue == "book-a")
}
