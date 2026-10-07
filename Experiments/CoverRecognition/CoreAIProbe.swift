// Compile-only Core AI API probe. Excluded from the iOS 26 Swift Package.
// Requires an actual .aimodel for load and inference; the FastViT .mlpackage is not one.
import CoreAI
import Foundation

enum ProbeError: Error { case missingFunction }

@available(macOS 27, iOS 27, *)
func loadCoreAIFunction(from aimodelURL: URL) async throws -> InferenceFunction {
    let model = try await AIModel(contentsOf: aimodelURL)
    guard let function = try model.loadFunction(named: "main") else {
        throw ProbeError.missingFunction
    }
    return function
}

/// A converted image model would need compatible input/output descriptors.
/// This checks a signature only; it does not establish that FastViT was converted.
@available(macOS 27, iOS 27, *)
func inspectImageEmbeddingSignature(_ function: InferenceFunction) -> Bool {
    guard case .image(let image)? = function.descriptor.inputDescriptor(of: "image"),
          case .ndArray(let features)? = function.descriptor.outputDescriptor(of: "imageFeatures") else {
        return false
    }
    return image.width == 256 && image.height == 256 && features.shape == [768]
}

@available(macOS 27, iOS 27, *)
func runCoreAIArrayExample(_ function: InferenceFunction) async throws -> NDArray? {
    var input = NDArray(shape: [3, 4], scalarType: .float32)
    let view = input.mutableView(as: Float.self)
    if var elements = view.contiguousElements {
        for index in elements.indices { elements[index] = 0 }
    }
    var outputs = try await function.run(inputs: ["input": input])
    return outputs.remove("prediction")?.ndArray
}
