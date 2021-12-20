// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Platform",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "PlatformKit", targets: ["PlatformKit"]),
        .library(name: "PlatformDataKit", targets: ["PlatformDataKit"]),
        .library(name: "PlatformUIKit", targets: ["PlatformUIKit"]),
        .library(name: "PlatformKitMock", targets: ["PlatformKitMock"]),
        .library(name: "PlatformUIKitMock", targets: ["PlatformUIKitMock"])
    ],
    dependencies: [
        .package(
            name: "BigInt",
            url: "https://github.com/attaswift/BigInt.git",
            from: "5.2.1"
        ),
        .package(
            name: "Charts",
            url: "https://github.com/danielgindi/Charts.git",
            from: "3.6.0"
        ),
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(
            name: "RIBs",
            url: "https://github.com/uber/RIBs.git",
            from: "0.12.1"
        ),
        .package(
            name: "RxDataSources",
            url: "https://github.com/RxSwiftCommunity/RxDataSources.git",
            from: "5.0.2"
        ),
        .package(
            name: "RxSwift",
            url: "https://github.com/ReactiveX/RxSwift.git",
            from: "6.2.0"
        ),
        .package(
            name: "Nuke",
            url: "https://github.com/kean/Nuke.git",
            from: "10.3.1"
        ),
        .package(
            name: "PhoneNumberKit",
            url: "https://github.com/marmelroy/PhoneNumberKit.git",
            from: "3.3.3"
        ),
        .package(
            name: "Zxcvbn",
            url: "https://github.com/oliveratkinson-bc/zxcvbn-ios.git",
            .branch("swift-package-manager")
        ),
        .package(
            name: "swift-algorithms",
            url: "https://github.com/apple/swift-algorithms.git",
            from: "0.2.1"
        ),
        .package(
            name: "Stripe",
            url: "https://github.com/stripe/stripe-ios",
            from: "21.9.0"
        ),
        .package(
            name: "Frames",
            url: "https://github.com/checkout/frames-ios.git",
            .upToNextMajor(from: "3.0.0")
        ),
        .package(path: "../Analytics"),
        .package(path: "../RxAnalytics"),
        .package(path: "../FeatureAuthentication"),
        .package(path: "../CommonCrypto"),
        .package(path: "../Localization"),
        .package(path: "../NetworkErrors"),
        .package(path: "../Network"),
        .package(path: "../Money"),
        .package(path: "../Test"),
        .package(path: "../Tool"),
        .package(path: "../RxTool"),
        .package(path: "../WalletPayload"),
        .package(path: "../UIComponents"),
        .package(path: "../FeatureOpenBanking"),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(path: "../ComponentLibrary"),
        .package(path: "../FeatureWithdrawalLocks")
    ],
    targets: [
        .target(
            name: "PlatformKit",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "AnalyticsKit", package: "Analytics"),
                // TODO: refactor this to use `FeatureAuthenticationDomain` as this shouldn't depend on DataKit
                .product(name: "FeatureAuthentication", package: "FeatureAuthentication"),
                .product(name: "CommonCryptoKit", package: "CommonCrypto"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "NetworkError", package: "NetworkErrors"),
                .product(name: "NabuNetworkError", package: "NetworkErrors"),
                .product(name: "NetworkKit", package: "Network"),
                .product(name: "MoneyKit", package: "Money"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "ComposableNavigation", package: "ComposableArchitectureExtensions"),
                .product(name: "ComposableArchitectureExtensions", package: "ComposableArchitectureExtensions"),
                .product(name: "RxToolKit", package: "RxTool"),
                .product(name: "WalletPayloadKit", package: "WalletPayload"),
                .product(name: "FeatureOpenBankingDomain", package: "FeatureOpenBanking"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Frames", package: "Frames"),
                .product(name: "Stripe", package: "Stripe")
            ],
            resources: [
                .copy("Services/Currencies/local-currencies-custodial.json"),
                .copy("Services/Currencies/local-currencies-erc20.json")
            ]
        ),
        .target(
            name: "PlatformDataKit",
            dependencies: [
                .target(name: "PlatformKit"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "NetworkError", package: "NetworkErrors"),
                .product(name: "NabuNetworkError", package: "NetworkErrors"),
                .product(name: "NetworkKit", package: "Network"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "PlatformUIKit",
            dependencies: [
                .target(name: "PlatformKit"),
                .product(name: "RIBs", package: "RIBs"),
                .product(name: "RxDataSources", package: "RxDataSources"),
                .product(name: "RxAnalyticsKit", package: "RxAnalytics"),
                .product(name: "Charts", package: "Charts"),
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "PhoneNumberKit", package: "PhoneNumberKit"),
                .product(name: "Zxcvbn", package: "Zxcvbn"),
                .product(name: "FeatureOpenBankingUI", package: "FeatureOpenBanking"),
                .product(name: "ComponentLibrary", package: "ComponentLibrary"),
                .product(name: "FeatureWithdrawalLocksUI", package: "FeatureWithdrawalLocks"),
                .product(name: "Frames", package: "Frames"),
                .product(name: "Stripe", package: "Stripe")
            ],
            resources: [
                .copy("PlatformUIKitAssets.xcassets")
            ]
        ),
        .target(
            name: "PlatformKitMock",
            dependencies: [
                .target(name: "PlatformKit"),
                .product(name: "NabuNetworkErrorMock", package: "NetworkErrors")
            ]
        ),
        .target(
            name: "PlatformUIKitMock",
            dependencies: [
                .target(name: "PlatformUIKit"),
                .product(name: "AnalyticsKitMock", package: "Analytics"),
                .product(name: "ToolKitMock", package: "Tool")
            ]
        ),
        .testTarget(
            name: "PlatformKitTests",
            dependencies: [
                .target(name: "PlatformKit"),
                .target(name: "PlatformKitMock"),
                .product(name: "MoneyKitMock", package: "Money"),
                .product(name: "FeatureAuthenticationMock", package: "FeatureAuthentication"),
                .product(name: "NabuNetworkErrorMock", package: "NetworkErrors"),
                .product(name: "NetworkKitMock", package: "Network"),
                .product(name: "ToolKitMock", package: "Tool"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "RxBlocking", package: "RxSwift"),
                .product(name: "RxTest", package: "RxSwift")
            ],
            resources: [
                .copy("Fixtures/wallet-data.json")
            ]
        ),
        .testTarget(
            name: "PlatformUIKitTests",
            dependencies: [
                .target(name: "PlatformKitMock"),
                .target(name: "PlatformUIKit"),
                .target(name: "PlatformUIKitMock"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "RxBlocking", package: "RxSwift"),
                .product(name: "RxTest", package: "RxSwift")
            ]
        )
    ]
)
