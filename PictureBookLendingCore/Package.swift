
import PackageDescription

let package = Package(
    name: "PictureBookLendingCore",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "PictureBookLendingCore",
            targets: ["PictureBookLendingCore"]),
    ],
    dependencies: [
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
