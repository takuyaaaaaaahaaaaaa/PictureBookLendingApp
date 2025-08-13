// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PictureBookLendingUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PictureBookLendingUI",
            targets: ["PictureBookLendingUI"])
    ],
    dependencies: [
        .package(path: "../PictureBookLendingDomain"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PictureBookLendingUI",
            dependencies: [
                .product(name: "PictureBookLendingDomain", package: "PictureBookLendingDomain"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ]
        ),
        .testTarget(
            name: "PictureBookLendingUITests",
            dependencies: ["PictureBookLendingUI"]
        ),
    ]
)
