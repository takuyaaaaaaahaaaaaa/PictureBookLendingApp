
import PackageDescription

let package = Package(
    name: "PictureBookLendingAdmin",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "PictureBookLendingAdmin",
            targets: ["PictureBookLendingAdmin"]),
    ],
    dependencies: [
        .package(path: "../PictureBookLendingCore"),
    ],
    targets: [
        .target(
            name: "PictureBookLendingAdmin",
            dependencies: [
                .product(name: "PictureBookLendingCore", package: "PictureBookLendingCore")
            ]),
        .testTarget(
            name: "PictureBookLendingAdminTests",
            dependencies: ["PictureBookLendingAdmin"]),
    ]
)
