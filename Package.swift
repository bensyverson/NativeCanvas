// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NativeCanvas",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "NativeCanvas",
            targets: ["NativeCanvas"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NativeCanvas",
        ),
        .testTarget(
            name: "NativeCanvasTests",
            dependencies: ["NativeCanvas"],
        ),
    ],
    swiftLanguageModes: [.v6],
)
