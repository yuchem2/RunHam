// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RunCatClone",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "RunCatClone",
            path: "Sources/RunCatClone",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "RunCatCloneTests",
            dependencies: ["RunCatClone"],
            path: "Tests/RunCatCloneTests"
        ),
    ]
)
