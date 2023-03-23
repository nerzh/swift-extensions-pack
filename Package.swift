// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SwiftExtensionsPack",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "SwiftExtensionsPack", targets: ["SwiftExtensionsPack"]),
    ],
    dependencies: [
        .package(name: "SwiftRegularExpression", url: "https://github.com/nerzh/swift-regular-expression.git", .upToNextMajor(from: "0.2.4")),
        .package(name: "swift-crypto", url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "2.0.0")),
    ],
    targets: [
        .target(name: "SwiftExtensionsPack",
                dependencies: [
                    .product(name: "SwiftRegularExpression", package: "SwiftRegularExpression"),
                    .product(name: "Crypto", package: "swift-crypto"),
                ]),
        .testTarget(
            name: "SwiftExtensionsPackTests", dependencies: ["SwiftExtensionsPack"]),
    ]
)
