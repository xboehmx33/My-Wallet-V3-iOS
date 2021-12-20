// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FeatureInterest",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "FeatureInterest",
            targets: ["FeatureInterestData", "FeatureInterestDomain", "FeatureInterestUI"]
        ),
        .library(name: "FeatureInterestDomain", targets: ["FeatureInterestDomain"])
    ],
    dependencies: [
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.28.1"
        ),
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(
            name: "RxSwift",
            url: "https://github.com/ReactiveX/RxSwift.git",
            from: "6.2.0"
        ),
        .package(path: "../Localization"),
        .package(path: "../FeatureTransaction"),
        .package(path: "../Network"),
        .package(path: "../NetworkErrors"),
        .package(path: "../UIComponents"),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(path: "../Platform"),
        .package(path: "../Tool")
    ],
    targets: [
        .target(
            name: "FeatureInterestDomain",
            dependencies: [
                .product(name: "FeatureTransactionDomain", package: "FeatureTransaction"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "NetworkError", package: "NetworkErrors"),
                .product(name: "NabuNetworkError", package: "NetworkErrors"),
                .product(name: "NetworkKit", package: "Network")
            ]
        ),
        .target(
            name: "FeatureInterestData",
            dependencies: [
                .target(name: "FeatureInterestDomain"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "NabuNetworkError", package: "NetworkErrors"),
                .product(name: "NetworkKit", package: "Network")
            ]
        ),
        .target(
            name: "FeatureInterestUI",
            dependencies: [
                .target(name: "FeatureInterestDomain"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "ComposableNavigation", package: "ComposableArchitectureExtensions"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "FeatureTransactionUI", package: "FeatureTransaction"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "PlatformUIKit", package: "Platform"),
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .testTarget(
            name: "FeatureInterestDataTests",
            dependencies: [
                .target(name: "FeatureInterestData")
            ]
        ),
        .testTarget(
            name: "FeatureInterestDomainTests",
            dependencies: [
                .target(name: "FeatureInterestDomain")
            ]
        ),
        .testTarget(
            name: "FeatureInterestUITests",
            dependencies: [
                .target(name: "FeatureInterestUI")
            ]
        )
    ]
)
