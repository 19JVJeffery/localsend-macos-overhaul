// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalSendApple",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "LocalSendCore",
            targets: ["LocalSendCore"]
        ),
        .library(
            name: "LocalSendUI",
            targets: ["LocalSendUI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LocalSendCore",
            dependencies: [],
            path: "Sources/LocalSendCore"
        ),
        .target(
            name: "LocalSendUI",
            dependencies: ["LocalSendCore"],
            path: "Sources/LocalSendUI"
        ),
        .testTarget(
            name: "LocalSendCoreTests",
            dependencies: ["LocalSendCore"],
            path: "Tests/LocalSendCoreTests"
        )
    ]
)
