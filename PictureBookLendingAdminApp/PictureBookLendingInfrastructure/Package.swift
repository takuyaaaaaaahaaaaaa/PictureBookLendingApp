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
        // Xcodeは動的ライブラリ(本パッケージ)のリンク時に、FirebaseAnalyticsCoreの推移依存のうち
        // 静的バイナリ(GoogleAppMeasurement)と GoogleUtilities/nanopb を引き込まない。
        // そのため下記3パッケージを直接依存として明示する（バージョン範囲はfirebase-ios-sdkと共存できる下限指定）。
        .package(url: "https://github.com/google/GoogleAppMeasurement", from: "12.18.0"),
        .package(url: "https://github.com/google/GoogleUtilities", from: "8.1.0"),
        .package(url: "https://github.com/firebase/nanopb", from: "2.30910.0"),
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
                // 推移依存のリンク漏れ対策（上記dependencies参照）。IDFA/AdSupportを含む
                // IdentitySupport系プロダクトは追加しないこと。
                .product(name: "GoogleAppMeasurementCore", package: "GoogleAppMeasurement"),
                .product(name: "GULNetwork", package: "GoogleUtilities"),
                .product(name: "GULLogger", package: "GoogleUtilities"),
                .product(name: "GULEnvironment", package: "GoogleUtilities"),
                .product(name: "GULNSData", package: "GoogleUtilities"),
                .product(name: "GULAppDelegateSwizzler", package: "GoogleUtilities"),
                .product(name: "GULMethodSwizzler", package: "GoogleUtilities"),
                .product(name: "nanopb", package: "nanopb"),
            ],
            path: "Sources",
            linkerSettings: [
                // 静的xcframeworkはCoreプロダクト経由では動的ライブラリにリンクされないため明示する（iOSのみ）。
                .linkedFramework("GoogleAppMeasurement", .when(platforms: [.iOS]))
            ]
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
