// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PromptLint",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "PLCore", targets: ["PLCore"]),
        .executable(name: "promptlint", targets: ["promptlint"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(name: "PLCore"),
        .executableTarget(
            name: "promptlint",
            dependencies: [
                "PLCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "PLCoreTests", dependencies: ["PLCore"]),
    ]
)
