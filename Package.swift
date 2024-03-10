// swift-tools-version: 5.9

import CompilerPluginSupport
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
                "_CoreIdentity",
                "_CSV",
                "_JSON",
                "_ModularDecodingEncoding",
                "_SWXMLHash",
                "_XMLCoder",
                "CorePersistence",
                "CorePersistenceMacros",
                "Proquint",
                "UUIDv6"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.0"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Merge.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master")
    ],
    targets: [
        .macro(
            name: "CorePersistenceMacros",
            dependencies: [
                "Swallow",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/CorePersistenceMacros"
        ),
        .target(
            name: "_ModularDecodingEncoding",
            dependencies: [
                "_CoreIdentity",
                "Merge",
                "Swallow"
            ],
            path: "Sources/_ModularDecodingEncoding",
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "_CoreIdentity",
            dependencies: [
                "CorePersistenceMacros",
                "Merge",
                "Proquint",
                "Swallow"
            ],
            path: "Sources/_CoreIdentity",
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "_CSV",
            dependencies: [
                "Swallow"
            ],
            path: "Sources/_CSV",
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "_JSON",
            dependencies: [
                "Swallow",
                "SwiftUIX"
            ],
            path: "Sources/_JSON",
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "_SWXMLHash",
            path: "Sources/_SWXMLHash",
            exclude: ["Info.plist"]
        ),
        .target(
            name: "_XMLCoder",
            dependencies: [
                "CorePersistence",
                "Swallow"
            ],
            path: "Sources/_XMLCoder",
            swiftSettings: []
        ),
        .target(
            name: "CorePersistence",
            dependencies: [
                "_CoreIdentity",
                "_JSON",
                "_ModularDecodingEncoding",
                "CorePersistenceMacros",
                "Merge",
                "Proquint",
                "Swallow"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
            ]
        ),
        .target(
            name: "Proquint",
            dependencies: [
                "Swallow"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-enable-library-evolution"
                ])
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
                "CorePersistence"
            ]
        ),
    ]
)
