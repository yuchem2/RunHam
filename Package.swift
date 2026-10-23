// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RunCatClone",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "RunCatClone",
            path: "Sources/RunCatClone"
        ),
        .testTarget(
            name: "RunCatCloneTests",
            dependencies: ["RunCatClone"],
            path: "Tests/RunCatCloneTests"
        ),
    ]
)
