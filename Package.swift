// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SwiftExtensionsPack",
    products: [
        .library(name: "SwiftExtensionsPack", targets: ["SwiftExtensionsPack"]),
    ],
    dependencies: [
        .package(name: "SwiftRegularExpression", url: "https://github.com/nerzh/swift-regular-expression.git", .upToNextMajor(from: "0.2.4")),
    ],
    targets: [
        .target(name: "SwiftExtensionsPack",
                dependencies: [
                    .product(name: "SwiftRegularExpression", package: "SwiftRegularExpression"),
                ]),
        .testTarget(
            name: "SwiftExtensionsPackTests", dependencies: ["SwiftExtensionsPack"]),
    ]
)
