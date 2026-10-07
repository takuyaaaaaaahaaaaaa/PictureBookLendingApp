// Run with: swift knn_lifecycle.swift /tmp/CoverKNNFixture.mlmodelc
// Vector-only Core ML lifecycle experiment. No cover image model is involved.
import CoreML
import Foundation

let source = URL(fileURLWithPath: CommandLine.arguments[1])
let saved = FileManager.default.temporaryDirectory.appendingPathComponent("cover-knn-\(UUID().uuidString).mlmodelc")
defer { try? FileManager.default.removeItem(at: saved) }

func vector(_ values: [Float]) throws -> MLMultiArray {
    let array = try MLMultiArray(shape: [3], dataType: .float32)
    for (index, value) in values.enumerated() { array[index] = NSNumber(value: value) }
    return array
}

func sample(_ values: [Float], label: String) throws -> MLFeatureProvider {
    try MLDictionaryFeatureProvider(dictionary: [
        "embedding": MLFeatureValue(multiArray: vector(values)),
        "bookID": MLFeatureValue(string: label),
    ])
}

let a = "book-a", b = "book-b"
let batch = MLArrayBatchProvider(array: [
    try sample([1, 0, 0], label: a),
    try sample([0, 1, 0], label: b),
])
let semaphore = DispatchSemaphore(value: 0)
var updateError: Error?
let task = try MLUpdateTask(forModelAt: source, trainingData: batch) { context in
    do { try context.model.write(to: saved) } catch { updateError = error }
    semaphore.signal()
}
task.resume()
guard semaphore.wait(timeout: .now() + 30) == .success else { fatalError("update timed out") }
if let updateError { throw updateError }
let model = try MLModel(contentsOf: saved)
let query = try MLDictionaryFeatureProvider(dictionary: ["embedding": MLFeatureValue(multiArray: vector([0.95, 0.05, 0]))])
let predicted = try model.prediction(from: query).featureValue(for: "bookID")?.stringValue
guard predicted == a else { fatalError("unexpected result: \(predicted ?? "nil")") }
print("Core ML update, save, reload, prediction: PASS (\(predicted!))")
