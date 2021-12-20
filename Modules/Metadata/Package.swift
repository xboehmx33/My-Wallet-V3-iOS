// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Metadata",
    platforms: [
        .iOS(.v14), .macOS(.v11)
    ],
    products: [
        .library(
            name: "MetadataKit",
            targets: ["MetadataKit"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/combine-schedulers",
            from: "0.1.2"
        ),
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(
            name: "secp256k1",
            url: "https://github.com/Boilertalk/secp256k1.swift.git",
            from: "0.1.0"
        ),
        .package(
            name: "CryptoSwift",
            url: "https://github.com/krzyzanowskim/CryptoSwift.git",
            from: "1.4.2"
        ),
        .package(path: "../Analytics"),
        .package(path: "../Network"),
        .package(path: "../NetworkErrors"),
        .package(path: "../Test"),
        .package(path: "../Tool")
    ],
    targets: [
        .target(
            name: "MetadataKit",
            dependencies: [
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "CombineSchedulers", package: "combine-schedulers"),
                .product(name: "NetworkError", package: "NetworkErrors")
            ]
        ),
        .testTarget(
            name: "MetadataKitTests",
            dependencies: [
                "MetadataKit",
                .product(name: "TestKit", package: "Test")
            ],
            resources: [
                .copy("Fixtures/Entries/Ethereum/ethereum_entry.json")
            ]
        )
    ]
)
