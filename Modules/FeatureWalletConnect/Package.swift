// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FeatureWalletConnect",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "FeatureWalletConnect",
            targets: [
                "FeatureWalletConnectDomain",
                "FeatureWalletConnectData",
                "FeatureWalletConnectUI"
            ]
        ),
        .library(
            name: "FeatureWalletConnectDomain",
            targets: ["FeatureWalletConnectDomain"]
        ),
        .library(
            name: "FeatureWalletConnectData",
            targets: ["FeatureWalletConnectData"]
        ),
        .library(
            name: "FeatureWalletConnectUI",
            targets: ["FeatureWalletConnectUI"]
        )
    ],
    dependencies: [
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.18.0"
        ),
        .package(
            name: "WalletConnectSwift",
            url: "https://github.com/crucheton-bc/WalletConnectSwift.git",
            from: "1.6.2"
        ),
        .package(path: "../Analytics"),
        .package(path: "../Localization"),
        .package(path: "../UIComponents"),
        .package(path: "../CryptoAssets"),
        .package(path: "../Platform")
    ],
    targets: [
        .target(
            name: "FeatureWalletConnectDomain",
            dependencies: [
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "EthereumKit", package: "CryptoAssets"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "WalletConnectSwift", package: "WalletConnectSwift")
            ]
        ),
        .target(
            name: "FeatureWalletConnectData",
            dependencies: [
                .target(name: "FeatureWalletConnectDomain"),
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "EthereumKit", package: "CryptoAssets"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "WalletConnectSwift", package: "WalletConnectSwift")
            ]
        ),
        .target(
            name: "FeatureWalletConnectUI",
            dependencies: [
                .target(name: "FeatureWalletConnectDomain"),
                .target(name: "FeatureWalletConnectData"),
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "PlatformUIKit", package: "Platform"),
                .product(name: "UIComponents", package: "UIComponents")
            ]
        )
    ]
)
