// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "RemoteNotifications",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "RemoteNotificationsKit",
            targets: ["RemoteNotificationsKit"]
        ),
        .library(
            name: "RemoteNotificationsKitMock",
            targets: ["RemoteNotificationsKitMock"]
        )
    ],
    dependencies: [
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
        .package(path: "../Analytics"),
        .package(path: "../Network"),
        .package(path: "../Platform"),
        .package(path: "../Tool"),
        .package(path: "../FeatureAuthentication")
    ],
    targets: [
        .target(
            name: "RemoteNotificationsKit",
            dependencies: [
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "PlatformUIKit", package: "Platform"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "FeatureAuthenticationDomain", package: "FeatureAuthentication")
            ]
        ),
        .target(
            name: "RemoteNotificationsKitMock",
            dependencies: [
                .target(name: "RemoteNotificationsKit")
            ],
            resources: [
                .copy("remote-notification-registration-failure.json"),
                .copy("remote-notification-registration-success.json")
            ]
        ),
        .testTarget(
            name: "RemoteNotificationsKitTests",
            dependencies: [
                .target(name: "RemoteNotificationsKit"),
                .target(name: "RemoteNotificationsKitMock"),
                .product(name: "AnalyticsKitMock", package: "Analytics"),
                .product(name: "NetworkKitMock", package: "Network"),
                .product(name: "RxBlocking", package: "RxSwift"),
                .product(name: "RxSwift", package: "RxSwift")
            ]
        )
    ]
)
