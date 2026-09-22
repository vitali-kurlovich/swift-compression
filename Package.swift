// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dependencies: [Package.Dependency]
let targets: [Target]
#if os(anyAppleOS)
    dependencies = []
    targets = [
        .target(
            name: "SwiftCompression"
        ),

        .testTarget(
            name: "SwiftCompressionTests",
            dependencies: ["SwiftCompression"]
        ),
    ]
#elseif os(Linux)
    dependencies[
        .package(url: "https://github.com/vitali-kurlovich/swift-xz", from: "0.1.0")
    ]

    targets = [
        .target(
            name: "SwiftCompression",
            dependencies: [
                .product(name: "Lzma", package: "swift-xz"),
            ]

        ),

        .testTarget(
            name: "SwiftCompressionTests",
            dependencies: ["SwiftCompression"]
        ),
    ]
#endif

let package = Package(
    name: "swift-compression",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v9),
        .tvOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftCompression",
            targets: ["SwiftCompression"]
        ),

    ],
    dependencies: dependencies,
    targets: targets,
    swiftLanguageModes: [.v6]
)
