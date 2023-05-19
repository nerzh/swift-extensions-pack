// swift-tools-version:5.8
import PackageDescription

let name: String = "SwiftExtensionsPack"

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/nerzh/swift-regular-expression.git", .upToNextMajor(from: "0.2.4")),
]

var targetDependencies: [Target.Dependency] = [
    .product(name: "SwiftRegularExpression", package: "swift-regular-expression"),
]

#if (os(Linux) || os(macOS))
packageDependencies.append(.package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "2.0.0")))
targetDependencies.append(.product(name: "Crypto", package: "swift-crypto"))
#else
#endif

let package = Package(
    name: name,
    platforms: [
        .iOS(.v11),
        .macOS(.v12)
    ],
    products: [
        .library(name: name, targets: [name])
    ],
    dependencies: packageDependencies,
    targets: [
        .target(
            name: name,
            dependencies: targetDependencies
        ),
        .testTarget(
            name: "\(name)Tests", dependencies: ["SwiftExtensionsPack"]),
    ]
)
