// swift-tools-version:5.10

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "CorePersistence",
    platforms: [
        .iOS(.v14),
        .macOS(.v13),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "CorePersistence",
            targets: [
                "_AEXML",
                "_CoreIdentity",
                "_CSV",
                "_JSON",
                "_JSONSchema",
                "_ModularDecodingEncoding",
                "_SWXMLHash",
                "_XMLCoder",
                "_SwiftFileSystem",
                "Proquint",
                "SwiftDocuments",
                "CorePersistence"
            ]
        ),
        .library(
            name: "FileProviderKit",
            targets: [
                "FileProviderKit"
            ]
        ),
        .library(
            name: "UUIDv6",
            targets: [
                "UUIDv6",
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/Merge.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master")
    ],
    targets: [
        .target(
            name: "_AEXML",
            dependencies: [
                "Swallow"
            ],
            path: "Sources/_AEXML",
            swiftSettings: []
        ),
        .target(
            name: "_ModularDecodingEncoding",
            dependencies: [
                "_CoreIdentity",
                "Merge",
                "Swallow"
            ],
            path: "Sources/_ModularDecodingEncoding",
            swiftSettings: []
        ),
        .target(
            name: "_CoreIdentity",
            dependencies: [
                "Merge",
                "Proquint",
                "Swallow",
                .product(name: "SwallowMacrosClient", package: "Swallow"),
            ],
            path: "Sources/_CoreIdentity",
            swiftSettings: []
        ),
        .target(
            name: "_CSV",
            dependencies: [
                "Swallow"
            ],
            path: "Sources/_CSV",
            swiftSettings: []
        ),
        .target(
            name: "_JSON",
            dependencies: [
                "Swallow"
            ],
            path: "Sources/_JSON",
            swiftSettings: []
        ),
        .target(
            name: "_JSONSchema",
            dependencies: [
                "_JSON",
                "Swallow"
            ],
            path: "Sources/_JSONSchema",
            swiftSettings: []
        ),
        .target(
            name: "_SWXMLHash",
            dependencies: [],
            path: "Sources/_SWXMLHash",
            exclude: ["Info.plist"]
        ),
        .target(
            name: "_XMLCoder",
            dependencies: [],
            path: "Sources/_XMLCoder",
            swiftSettings: []
        ),
        .target(
            name: "_SwiftFileSystem",
            dependencies: [
                "_ModularDecodingEncoding",
                "Merge",
                "Swallow",
            ],
            path: "Sources/_SwiftFileSystem"
        ),
        .target(
            name: "SwiftDocuments",
            dependencies: [
                "_CoreIdentity",
                "_ModularDecodingEncoding",
                "_SwiftFileSystem",
                "Merge",
                "Swallow",
                .product(name: "SwallowMacrosClient", package: "Swallow"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([])
            ]
        ),
        .target(
            name: "CorePersistence",
            dependencies: [
                "_CoreIdentity",
                "_JSON",
                "_JSONSchema",
                "_ModularDecodingEncoding",
                "_SwiftFileSystem",
                "Merge",
                "Proquint",
                "SwiftDocuments",
                "Swallow",
                .product(name: "SwallowMacrosClient", package: "Swallow"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("AccessLevelOnImport"),
                .unsafeFlags([])
            ]
        ),
        .target(
            name: "FileProviderKit",
            dependencies: [
                "CorePersistence",
            ]
        ),
        .target(
            name: "Proquint",
            dependencies: [
                "Swallow"
            ],
            swiftSettings: []
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
                "_JSON",
                "_JSONSchema",
                "CorePersistence"
            ],
            sources: [
                "CorePersistence"
            ]
        ),
    ]
)
