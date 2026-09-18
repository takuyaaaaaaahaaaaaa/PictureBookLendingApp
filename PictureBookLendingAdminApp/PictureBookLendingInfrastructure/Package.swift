// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PictureBookLendingInfrastructure",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PictureBookLendingInfrastructure",
            targets: ["PictureBookLendingInfrastructure"])
    ],
    dependencies: [
        .package(path: "../PictureBookLendingDomain"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.18.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PictureBookLendingInfrastructure",
            dependencies: [
                .product(name: "PictureBookLendingDomain", package: "PictureBookLendingDomain"),
                // FirebaseAnalyticsWithoutAdIdSupport は firebase-ios-sdk から削除済み（§5参照）。
                // AdSupport/IDFAを一切リンクしない後継プロダクトとして FirebaseAnalyticsCore を使う。
                .product(name: "FirebaseAnalyticsCore", package: "firebase-ios-sdk"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PictureBookLendingInfrastructureTests",
            dependencies: [
                "PictureBookLendingInfrastructure"
            ],
            path: "Tests"
        ),
    ]
)
