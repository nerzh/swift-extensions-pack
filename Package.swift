// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-extensions-pack",
    products: [
        .library(name: "swift-extensions-pack", targets: ["swift-extensions-pack"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "swift-extensions-pack", dependencies: []),
        .testTarget(
            name: "swift-extensions-packTests", dependencies: ["swift-extensions-pack"]),
    ]
)
