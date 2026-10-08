import CoreGraphics
import CoreML
import CoreVideo
import Foundation

/// Apple FastViT-T8 headless: 256x256 RGB -> 768 Float32 features.
/// The model and preprocessing version must be stored with the index.
public struct CoreMLCoverEncoder {
    public static let version = "FastViTT8F16Headless-1.0-centerCrop-BGRA-v1"
    private let model: MLModel

    public init(modelURL: URL) throws {
        let compiledURL = modelURL.pathExtension == "mlmodelc"
            ? modelURL : try MLModel.compileModel(at: modelURL)
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuOnly
        model = try MLModel(contentsOf: compiledURL, configuration: configuration)
    }

    public func encode(_ image: CGImage) throws -> [Float] {
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, 256, 256, kCVPixelFormatType_32BGRA,
                                         [kCVPixelBufferCGImageCompatibilityKey: true,
                                          kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary,
                                         &buffer)
        guard status == kCVReturnSuccess, let buffer else { throw CoverIndexError.invalidFeaturePrint }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: 256, height: 256,
                                      bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue |
                                          CGBitmapInfo.byteOrder32Little.rawValue) else {
            throw CoverIndexError.invalidFeaturePrint
        }
        let side = min(image.width, image.height)
        let source = CGRect(x: (image.width - side) / 2, y: (image.height - side) / 2, width: side, height: side)
        guard let crop = image.cropping(to: source) else { throw CoverIndexError.invalidFeaturePrint }
        context.draw(crop, in: CGRect(x: 0, y: 0, width: 256, height: 256))
        let input = try MLDictionaryFeatureProvider(dictionary: ["image": MLFeatureValue(pixelBuffer: buffer)])
        guard let features = try model.prediction(from: input).featureValue(for: "imageFeatures")?.multiArrayValue,
              features.count == 768 else { throw CoverIndexError.invalidFeaturePrint }
        return (0..<features.count).map { features[$0].floatValue }
    }
}
