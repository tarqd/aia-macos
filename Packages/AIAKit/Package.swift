// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AIAKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "AIAKit", targets: ["AIAKit"]),
    ],
    targets: [
        .target(
            name: "AIAKit",
            resources: [.copy("Resources/aia-v1")]
        ),
        .testTarget(
            name: "AIAKitTests",
            dependencies: ["AIAKit"]
        ),
    ]
)
