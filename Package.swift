// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftExtensionsPack",
    products: [
        .library(name: "SwiftExtensionsPack", targets: ["SwiftExtensionsPack"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftExtensionsPack", dependencies: []),
        .testTarget(
            name: "SwiftExtensionsPackTests", dependencies: ["SwiftExtensionsPack"]),
    ]
)
