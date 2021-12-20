// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "CryptoAssets",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "BitcoinCashKit", targets: ["BitcoinCashKit"]),
        .library(name: "BitcoinChainKit", targets: ["BitcoinChainKit"]),
        .library(name: "BitcoinKit", targets: ["BitcoinKit"]),
        .library(name: "EthereumKit", targets: ["EthereumKit"]),
        .library(name: "ERC20Kit", targets: ["ERC20Kit"]),
        .library(name: "ERC20DataKit", targets: ["ERC20DataKit"]),
        .library(name: "StellarKit", targets: ["StellarKit"]),
        .library(name: "BitcoinKitMock", targets: ["BitcoinKitMock"]),
        .library(name: "EthereumKitMock", targets: ["EthereumKitMock"]),
        .library(name: "ERC20KitMock", targets: ["ERC20KitMock"]),
        .library(name: "StellarKitMock", targets: ["StellarKitMock"])
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
        .package(
            name: "RxSwift",
            url: "https://github.com/ReactiveX/RxSwift.git",
            from: "6.2.0"
        ),
        .package(
            name: "stellarsdk",
            url: "https://github.com/Soneso/stellar-ios-mac-sdk.git",
            .exact("2.0.2")
        ),
        .package(path: "../Network"),
        .package(path: "../NetworkErrors"),
        .package(path: "../Money"),
        .package(path: "../Platform"),
        .package(path: "../FeatureTransaction"),
        .package(path: "../Test"),
        .package(path: "../Tool")
    ],
    targets: [
        .target(
            name: "BitcoinCashKit",
            dependencies: [
                .target(name: "BitcoinChainKit"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "BitcoinChainKit",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "FeatureTransactionDomain", package: "FeatureTransaction"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "BitcoinKit",
            dependencies: [
                .target(name: "BitcoinChainKit"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "ERC20DataKit",
            dependencies: [
                .product(name: "DIKit", package: "DIKit"),
                .target(name: "ERC20Kit"),
                .product(name: "NetworkKit", package: "Network"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "ERC20Kit",
            dependencies: [
                .target(name: "EthereumKit"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "EthereumKit",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "FeatureTransactionDomain", package: "FeatureTransaction"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "StellarKit",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "FeatureTransactionDomain", package: "FeatureTransaction"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "stellarsdk", package: "stellarsdk"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "BitcoinKitMock",
            dependencies: [
                .target(name: "BitcoinKit")
            ]
        ),
        .target(
            name: "ERC20DataKitMock",
            dependencies: [
                .target(name: "ERC20DataKit")
            ]
        ),
        .target(
            name: "ERC20KitMock",
            dependencies: [
                .target(name: "ERC20Kit")
            ]
        ),
        .target(
            name: "EthereumKitMock",
            dependencies: [
                .target(name: "EthereumKit"),
                .product(name: "NetworkError", package: "NetworkErrors"),
                .product(name: "TestKit", package: "Test")
            ]
        ),
        .target(
            name: "StellarKitMock",
            dependencies: [
                .target(name: "StellarKit")
            ]
        ),
        .testTarget(
            name: "BitcoinCashKitTests",
            dependencies: [
                .target(name: "BitcoinCashKit"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "RxBlocking", package: "RxSwift"),
                .product(name: "RxTest", package: "RxSwift")
            ]
        ),
        .testTarget(
            name: "BitcoinChainKitTests",
            dependencies: [
                .target(name: "BitcoinChainKit"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "RxBlocking", package: "RxSwift"),
                .product(name: "RxTest", package: "RxSwift")
            ]
        ),
        .testTarget(
            name: "BitcoinKitTests",
            dependencies: [
                .target(name: "BitcoinKit"),
                .target(name: "BitcoinKitMock"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "RxBlocking", package: "RxSwift"),
                .product(name: "RxTest", package: "RxSwift")
            ]
        ),
        .testTarget(
            name: "ERC20DataKitTests",
            dependencies: [
                .target(name: "ERC20DataKit"),
                .target(name: "ERC20DataKitMock"),
                .target(name: "ERC20Kit"),
                .target(name: "ERC20KitMock"),
                .target(name: "EthereumKit"),
                .product(name: "MoneyKitMock", package: "Money"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "PlatformKitMock", package: "Platform"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "RxBlocking", package: "RxSwift"),
                .product(name: "RxTest", package: "RxSwift")
            ]
        ),
        .testTarget(
            name: "ERC20KitTests",
            dependencies: [
                .target(name: "ERC20Kit"),
                .target(name: "ERC20KitMock"),
                .product(name: "PlatformKitMock", package: "Platform"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "RxBlocking", package: "RxSwift"),
                .product(name: "RxTest", package: "RxSwift")
            ]
        ),
        .testTarget(
            name: "EthereumKitTests",
            dependencies: [
                .target(name: "EthereumKit"),
                .target(name: "EthereumKitMock"),
                .product(name: "PlatformKitMock", package: "Platform"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "RxBlocking", package: "RxSwift"),
                .product(name: "RxTest", package: "RxSwift")
            ]
        ),
        .testTarget(
            name: "StellarKitTests",
            dependencies: [
                .target(name: "StellarKit"),
                .target(name: "StellarKitMock"),
                .product(name: "PlatformKitMock", package: "Platform"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "RxBlocking", package: "RxSwift")
            ],
            resources: [
                .copy("account_response.json")
            ]
        )
    ]
)
