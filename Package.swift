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
            targets: [
                "CorePersistence",
                "HadeanIdentifiers",
                "Proquint",
                "UUIDv6"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/Merge.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master")
    ],
    targets: [
        .target(
            name: "CorePersistence",
            dependencies: [
                "Merge",
                "Swallow"
            ]
        ),
        .target(
            name: "HadeanIdentifiers",
            dependencies: [
                "CorePersistence",
                "Proquint"
            ]
        ),
        .target(
            name: "Proquint",
            dependencies: [
                "CorePersistence"
            ]
        ),
        .target(
            name: "UUIDv6",
            dependencies: [
                "CorePersistence"
            ]
        ),
        .testTarget(
            name: "CorePersistenceTests",
            dependencies: [
                "CorePersistence",
                "HadeanIdentifiers"
            ]
        ),
    ]
)
