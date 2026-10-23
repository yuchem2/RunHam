// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RunHam",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "RunHam",
            path: "Sources/RunHam",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "RunHamTests",
            dependencies: ["RunHam"],
            path: "Tests/RunHamTests"
        ),
    ]
)
