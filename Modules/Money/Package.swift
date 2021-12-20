// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Money",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(
            name: "MoneyKit",
            targets: ["MoneyKit"]
        ),
        .library(
            name: "MoneyKitMock",
            targets: ["MoneyKitMock"]
        )
    ],
    dependencies: [
        .package(
            name: "BigInt",
            url: "https://github.com/attaswift/BigInt.git",
            from: "5.2.1"
        ),
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(path: "../Tool")
    ],
    targets: [
        .target(
            name: "MoneyKit",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "ToolKit", package: "Tool")
            ],
            resources: [
                .copy("Resources/local-currencies-custodial.json"),
                .copy("Resources/local-currencies-erc20.json")
            ]
        ),
        .target(
            name: "MoneyKitMock",
            dependencies: [
                .target(name: "MoneyKit")
            ]
        ),
        .testTarget(
            name: "MoneyKitTests",
            dependencies: [
                .target(name: "MoneyKit"),
                .target(name: "MoneyKitMock")
            ]
        )
    ]
)
