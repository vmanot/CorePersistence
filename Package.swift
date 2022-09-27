// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "CorePersistence",
    platforms: [
        .iOS(.v14),
        .macOS(.v12),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "CorePersistence",
            targets: ["CorePersistence"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/FoundationX.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master")
    ],
    targets: [
        .target(
            name: "CorePersistence",
            dependencies: ["FoundationX", "Swallow"],
            path: "Sources"
        ),
        .testTarget(
            name: "CorePersistenceTests",
            dependencies: ["CorePersistence"],
            path: "Tests"
        )
    ]
)
