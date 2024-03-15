// swift-tools-version:5.8
import PackageDescription

let name: String = "SwiftExtensionsPack"

var packageDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/nerzh/swift-regular-expression.git", .upToNextMajor(from: "0.2.4")),
    .package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "2.0.0")),
    .package(url: "https://github.com/bytehubio/ed25519", .upToNextMajor(from: "1.0.0")),
]

var targetDependencies: [Target.Dependency] = [
    .product(name: "SwiftRegularExpression", package: "swift-regular-expression"),
    .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux])),
    .product(name: "Ed25519", package: "ed25519"),
]

var platforms: [SupportedPlatform] = [
    .iOS(.v13),
    .macOS(.v10_15)
]

//#if (os(Linux) || os(macOS))
//packageDependencies.append(.package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "2.0.0")))
//targetDependencies.append(.product(name: "Crypto", package: "swift-crypto"))
//platforms = [
//    .iOS(.v13)
//]
//#else
//#endif

let package = Package(
    name: name,
    platforms: platforms,
    products: [
        .library(name: name, targets: [name]),
    ],
    dependencies: packageDependencies,
    targets: [
        .target(
            name: name,
            dependencies: targetDependencies
        ),
        .testTarget(
            name: "\(name)Tests", dependencies: ["SwiftExtensionsPack"]
        ),
    ]
)
