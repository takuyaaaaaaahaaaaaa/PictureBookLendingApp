// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoverRecognitionPoC",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "CoverRecognitionPoC", targets: ["CoverRecognitionPoC"])],
    targets: [
        .target(name: "CoverRecognitionPoC"),
        .testTarget(name: "CoverRecognitionPoCTests", dependencies: ["CoverRecognitionPoC"], resources: [.copy("Resources/CoverKNNFixture.mlmodelc")]),
    ]
)
