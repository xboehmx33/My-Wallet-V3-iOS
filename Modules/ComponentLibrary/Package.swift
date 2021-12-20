// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ComponentLibrary",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "ComponentLibrary",
            targets: [
                "ComponentLibrary"
            ]
        ),
        .library(
            name: "Examples",
            targets: [
                "Examples"
            ]
        )
    ],
    dependencies: [
        .package(
            name: "SnapshotTesting",
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.9.0"
        ),
        .package(
            name: "swift-case-paths",
            url: "https://github.com/pointfreeco/swift-case-paths",
            from: "0.7.0"
        ),
        .package(
            name: "swift-markdown",
            url: "https://github.com/apple/swift-markdown.git",
            .revision("1023300b1d6847360ac9ceebbcff2bccacbcf2a5")
        )
    ],
    targets: [
        .target(
            name: "ComponentLibrary",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "Markdown", package: "swift-markdown")
            ],
            resources: [
                .process("Resources/Fonts")
            ]
        ),
        .testTarget(
            name: "ComponentLibraryTests",
            dependencies: [
                "ComponentLibrary",
                "SnapshotTesting",
                "Examples"
            ],
            exclude: [
                "__Snapshots__",
                "1 - Base/__Snapshots__",
                "2 - Primitives/__Snapshots__",
                "2 - Primitives/Buttons/__Snapshots__",
                "3 - Compositions/__Snapshots__",
                "3 - Compositions/Rows/__Snapshots__",
                "3 - Compositions/SectionHeaders/__Snapshots__",
                "3 - Compositions/Sheets/__Snapshots__",
                "Utilities/__Snapshots__"
            ]
        ),
        .target(
            name: "Examples",
            dependencies: [
                "ComponentLibrary"
            ]
        )
    ]
)
