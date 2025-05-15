
import PackageDescription

let package = Package(
    name: "PictureBookLendingUser",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "PictureBookLendingUser",
            targets: ["PictureBookLendingUser"]),
    ],
    dependencies: [
        .package(path: "../PictureBookLendingCore"),
    ],
    targets: [
        .target(
            name: "PictureBookLendingUser",
            dependencies: [
                .product(name: "PictureBookLendingCore", package: "PictureBookLendingCore")
            ]),
        .testTarget(
            name: "PictureBookLendingUserTests",
            dependencies: ["PictureBookLendingUser"]),
    ]
)
