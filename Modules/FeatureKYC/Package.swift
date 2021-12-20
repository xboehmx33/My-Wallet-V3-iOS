// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FeatureKYC",
    defaultLocalization: "en",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "FeatureKYC", targets: ["FeatureKYCDomain", "FeatureKYCUI"]),
        .library(name: "FeatureKYCDomain", targets: ["FeatureKYCDomain"]),
        .library(name: "FeatureKYCUI", targets: ["FeatureKYCUI"]),
        .library(name: "FeatureKYCMock", targets: ["FeatureKYCDomainMock", "FeatureKYCUIMock"])
    ],
    dependencies: [
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.24.0"
        ),
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
        .package(
            name: "RxSwift",
            url: "https://github.com/ReactiveX/RxSwift.git",
            from: "6.2.0"
        ),
        .package(
            name: "Veriff",
            url: "https://github.com/Veriff/veriff-ios-spm.git",
            .exact("4.17.0")
        ),
        .package(path: "../Analytics"),
        .package(path: "../FeatureAuthentication"),
        .package(path: "../Localization"),
        .package(path: "../Network"),
        .package(path: "../Platform"),
        .package(path: "../Test"),
        .package(path: "../Tool"),
        .package(path: "../UIComponents"),
        .package(path: "../ComponentLibrary"),
        .package(path: "../ComposableArchitectureExtensions")
    ],
    targets: [
        .target(
            name: "FeatureKYCDomain",
            dependencies: [
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "NetworkKit", package: "Network")
            ]
        ),
        .target(
            name: "FeatureKYCUI",
            dependencies: [
                .target(name: "FeatureKYCDomain"),
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ComposableNavigation", package: "ComposableArchitectureExtensions"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "FeatureAuthenticationDomain", package: "FeatureAuthentication"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "NetworkKit", package: "Network"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "PlatformUIKit", package: "Platform"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "ComponentLibrary", package: "ComponentLibrary"),
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "Veriff", package: "Veriff")
            ],
            resources: [
                .copy("Media.xcassets")
            ]
        ),
        .target(
            name: "FeatureKYCDomainMock",
            dependencies: [
                .target(name: "FeatureKYCDomain"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "PlatformUIKit", package: "Platform"),
                .product(name: "RxSwift", package: "RxSwift")
            ]
        ),
        .target(
            name: "FeatureKYCUIMock",
            dependencies: [
                .target(name: "FeatureKYCDomain"),
                .target(name: "FeatureKYCUI"),
                .product(name: "PlatformKit", package: "Platform")
            ]
        ),
        .testTarget(
            name: "FeatureKYCDomainTests",
            dependencies: [
                .target(name: "FeatureKYCDomain"),
                .product(name: "PlatformKitMock", package: "Platform"),
                .product(name: "TestKit", package: "Test")
            ]
        ),
        .testTarget(
            name: "FeatureKYCUITests",
            dependencies: [
                .target(name: "FeatureKYCDomainMock"),
                .target(name: "FeatureKYCUI"),
                .target(name: "FeatureKYCUIMock"),
                .product(name: "AnalyticsKitMock", package: "Analytics"),
                .product(name: "FeatureAuthenticationMock", package: "FeatureAuthentication"),
                .product(name: "PlatformKitMock", package: "Platform"),
                .product(name: "PlatformUIKitMock", package: "Platform"),
                .product(name: "ToolKitMock", package: "Tool"),
                .product(name: "TestKit", package: "Test")
            ],
            exclude: [
                "_New_KYC/Limits/__Snapshots__",
                "_New_KYC/EmailVerification/__Snapshots__"
            ]
        )
    ]
)
