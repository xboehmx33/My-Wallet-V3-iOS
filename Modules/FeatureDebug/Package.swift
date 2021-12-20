// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FeatureDebug",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "FeatureDebug", targets: ["FeatureDebugUI"]),
        .library(name: "FeatureDebugUI", targets: ["FeatureDebugUI"])
    ],
    dependencies: [
        .package(
            name: "RxSwift",
            url: "https://github.com/ReactiveX/RxSwift.git",
            from: "6.2.0"
        ),
        .package(
            name: "RxDataSources",
            url: "https://github.com/RxSwiftCommunity/RxDataSources.git",
            from: "5.0.2"
        ),
        .package(path: "../FeatureTransaction"),
        .package(path: "../Platform"),
        .package(path: "../Tool"),
        .package(path: "../ComponentLibrary")
    ],
    targets: [
        .target(
            name: "FeatureDebugUI",
            dependencies: [
                .product(name: "FeatureTransactionUI", package: "FeatureTransaction"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "PlatformUIKit", package: "Platform"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxDataSources", package: "RxDataSources"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "Examples", package: "ComponentLibrary")
            ]
        ),
        .testTarget(
            name: "FeatureDebugUITests",
            dependencies: [
                .target(name: "FeatureDebugUI")
            ]
        )
    ]
)
