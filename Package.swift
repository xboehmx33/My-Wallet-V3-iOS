// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Blockchain",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "AnalyticsKit",
            targets: ["AnalyticsKit"]
        ),
        .library(
            name: "SharedComponentLibrary",
            targets: ["SharedComponentLibrary"]
        ),
        .library(
            name: "FeatureOpenBankingUI",
            targets: ["FeatureOpenBankingUI"]
        ),
        .library(
            name: "FeatureOpenBankingDomain",
            targets: ["FeatureOpenBankingDomain"]
        ),
        .library(
            name: "FeatureOpenBankingData",
            targets: ["FeatureOpenBankingData"]
        ),
        .library(
            name: "ComposableNavigation",
            targets: ["ComposableNavigation"]
        ),
        .library(
            name: "NetworkError",
            targets: ["NetworkError"]
        ),
        .library(
            name: "WalletNetworkKit",
            targets: ["WalletNetworkKit"]
        ),
        .library(
            name: "ToolKit",
            targets: ["ToolKit"]
        ),
        .library(
            name: "Session",
            targets: ["Session"]
        ),
        .library(
            name: "UIComponentsKit",
            targets: ["UIComponentsKit"]
        )
    ],
    dependencies: [
        .package(
            name: "combine-schedulers",
            url: "https://github.com/pointfreeco/combine-schedulers",
            from: "0.5.0"
        ),
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.28.1"
        ),
        .package(
            name: "swift-case-paths",
            url: "https://github.com/pointfreeco/swift-case-paths",
            from: "0.7.0"
        ),
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(
            name: "BigInt",
            url: "https://github.com/attaswift/BigInt.git",
            from: "5.2.1"
        ),
        .package(
            name: "swift-markdown",
            url: "https://github.com/apple/swift-markdown.git",
            .revision("1023300b1d6847360ac9ceebbcff2bccacbcf2a5")
        )
    ],
    targets: [
        .target(
            name: "AnalyticsKit",
            path: "Modules/Analytics/Sources/AnalyticsKit"
        ),
        .testTarget(
            name: "AnalyticsKitTests",
            path: "Modules/Analytics/Tests/AnalyticsKitTests"
        ),
        .target(
            name: "SharedComponentLibrary",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Modules/ComponentLibrary/Sources/ComponentLibrary",
            resources: [
                .process("Resources/Fonts")
            ]
        ),
        .testTarget(
            name: "SharedComponentLibraryTests",
            path: "Modules/ComponentLibrary/Tests/ComponentLibraryTests"
        ),
        .target(
            name: "ComposableNavigation",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ],
            path: "Modules/ComposableArchitectureExtensions/Sources/ComposableNavigation",
            exclude: [
                "README.md"
            ]
        ),
        .target(
            name: "NetworkError",
            path: "Modules/NetworkErrors/Sources/NetworkError"
        ),
        .target(
            name: "WalletNetworkKit",
            dependencies: [
                .product(name: "DIKit", package: "DIKit"),
                .target(name: "AnalyticsKit"),
                .target(name: "ToolKit"),
                .target(name: "NetworkError")
            ],
            path: "Modules/Network/Sources/NetworkKit"
        ),
        .target(
            name: "ToolKit",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "BigInt", package: "BigInt")
            ],
            path: "Modules/Tool/Sources/ToolKit"
        ),
        .target(
            name: "Session",
            path: "Modules/Session/Sources/Session"
        ),
        .target(
            name: "UIComponentsKit",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .target(name: "ToolKit"),
                .target(name: "SharedComponentLibrary")
            ],
            path: "Modules/UIComponents/UIComponentsKit",
            resources: [
                .copy("Lottie/loader_v2.json")
            ]
        ),
        .target(
            name: "FeatureOpenBankingDomain",
            dependencies: [
                .product(name: "CombineSchedulers", package: "combine-schedulers"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .target(name: "NetworkError"),
                .target(name: "Session"),
                .target(name: "ToolKit")
            ],
            path: "Modules/FeatureOpenBanking/Sources/FeatureOpenBankingDomain"
        ),
        .target(
            name: "FeatureOpenBankingData",
            dependencies: [
                .product(name: "CombineSchedulers", package: "combine-schedulers"),
                .target(name: "FeatureOpenBankingDomain"),
                .target(name: "WalletNetworkKit"),
                .target(name: "Session"),
                .target(name: "ToolKit")
            ],
            path: "Modules/FeatureOpenBanking/Sources/FeatureOpenBankingData"
        ),
        .target(
            name: "FeatureOpenBankingUI",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .target(name: "FeatureOpenBankingDomain"),
                .target(name: "FeatureOpenBankingData"),
                .target(name: "ComposableNavigation"),
                .target(name: "SharedComponentLibrary"),
                .target(name: "UIComponentsKit")
            ],
            path: "Modules/FeatureOpenBanking/Sources/FeatureOpenBankingUI"
        )
    ],
    swiftLanguageVersions: [.v5]
)
