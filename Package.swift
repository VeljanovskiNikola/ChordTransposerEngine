// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChordTransposerEngine",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "ChordTransposerEngine",
            targets: ["ChordTransposerEngine"]
        )
    ],
    targets: [
        .target(
            name: "ChordTransposerEngine",
            path: "Sources/ChordTransposerEngine"
        ),
        .testTarget(
            name: "ChordTransposerEngineTests",
            dependencies: ["ChordTransposerEngine"],
            path: "Tests/ChordTransposerEngineTests"
        )
    ]
)
