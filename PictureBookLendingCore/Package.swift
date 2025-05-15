
import PackageDescription

let package = Package(
    name: "PictureBookLendingCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PictureBookLendingCore",
            targets: ["PictureBookLendingCore"]),
    ],
    targets: [
        .target(
            name: "PictureBookLendingCore",
            dependencies: []),
        .testTarget(
            name: "PictureBookLendingCoreTests",
            dependencies: ["PictureBookLendingCore"]),
    ]
)
