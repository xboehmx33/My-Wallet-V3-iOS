// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

/// An asset (crypto or fiat).
public struct AssetModel: Hashable {

    // MARK: - Public Properties

    /// The asset code (e.g. `USD`, `BTC`, etc.).
    public let code: String
    /// The asset display code (e.g. `USD`, `BTC`, etc.).
    public let displayCode: String
    /// The asset type.
    public let kind: AssetModelType
    /// The asset name (e.g. `US Dollar`, `Bitcoin`, etc.).
    public let name: String
    /// The asset precision, representing the maximum number of fraction digits.
    public let precision: Int
    /// The list of supported asset products.
    public let products: [AssetModelProduct]
    /// The URL to the asset logo.
    public let logoPngUrl: String?
    /// The asset spot color.
    public let spotColor: String?

    // MARK: - Internal Properties

    /// Temporary sorting index, while full dynamic asset migration is in progress.
    let sortIndex: Int

    // MARK: - Setup

    /// Creates an AssetModel asset.
    ///
    /// - Parameters:
    ///   - assetResponse: A supported SupportedAssetsResponse.Asset object.
    ///   - sortIndex:     A sorting index.
    init?(assetResponse: SupportedAssetsResponse.Asset, sortIndex: Int) {
        code = assetResponse.symbol
        displayCode = assetResponse.displaySymbol ?? assetResponse.symbol
        name = assetResponse.name
        precision = assetResponse.precision
        products = assetResponse.products.compactMap(AssetModelProduct.init)
        logoPngUrl = assetResponse.type.logoPngUrl
        spotColor = assetResponse.type.spotColor

        switch assetResponse.type.name {
        case SupportedAssetsResponse.Asset.AssetType.Name.coin.rawValue:
            self.sortIndex = 10 + sortIndex
            kind = .coin(minimumOnChainConfirmations: assetResponse.type.minimumOnChainConfirmations ?? 0)
        case SupportedAssetsResponse.Asset.AssetType.Name.celoToken.rawValue:
            self.sortIndex = 1000 + sortIndex
            kind = .celoToken
        case SupportedAssetsResponse.Asset.AssetType.Name.erc20.rawValue:
            guard assetResponse.type.parentChain == NonCustodialCoinCode.ethereum.rawValue else {
                return nil
            }
            guard let erc20Address = assetResponse.type.erc20Address else {
                return nil
            }
            self.sortIndex = 10000 + sortIndex
            kind = .erc20(contractAddress: erc20Address)
        case SupportedAssetsResponse.Asset.AssetType.Name.fiat.rawValue:
            self.sortIndex = sortIndex
            kind = .fiat
        default:
            return nil
        }
    }

    init(
        code: String,
        displayCode: String,
        kind: AssetModelType,
        name: String,
        precision: Int,
        products: [AssetModelProduct],
        logoPngUrl: String?,
        spotColor: String?,
        sortIndex: Int
    ) {
        self.code = code
        self.displayCode = displayCode
        self.kind = kind
        self.name = name
        self.precision = precision
        self.products = products
        self.logoPngUrl = logoPngUrl
        self.spotColor = spotColor
        self.sortIndex = sortIndex
    }

    // MARK: - Internal Methods

    /// Creates a new AssetModel asset by replacing the current list of supported asset products.
    ///
    /// - Parameter products: A list of supported asset products.
    func with(products: [AssetModelProduct]) -> AssetModel {
        AssetModel(
            code: code,
            displayCode: displayCode,
            kind: kind,
            name: name,
            precision: precision,
            products: products,
            logoPngUrl: logoPngUrl,
            spotColor: spotColor,
            sortIndex: sortIndex
        )
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(kind)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.code == rhs.code
            && lhs.kind == rhs.kind
    }

    public func supports(product: AssetModelProduct) -> Bool {
        products.contains(product)
    }
}

extension AssetModel {

    public static var bitcoin: AssetModel {
        AssetModel(
            code: "BTC",
            displayCode: "BTC",
            kind: .coin(minimumOnChainConfirmations: 2),
            name: "Bitcoin",
            precision: 8,
            products: AssetModelProduct.allCases,
            logoPngUrl: nil,
            spotColor: "FF9B22",
            sortIndex: 1
        )
    }

    public static var bitcoinCash: AssetModel {
        AssetModel(
            code: "BCH",
            displayCode: "BCH",
            kind: .coin(minimumOnChainConfirmations: 3),
            name: "Bitcoin Cash",
            precision: 8,
            products: AssetModelProduct.allCases,
            logoPngUrl: nil,
            spotColor: "8DC351",
            sortIndex: 3
        )
    }

    public static var ethereum: AssetModel {
        AssetModel(
            code: "ETH",
            displayCode: "ETH",
            kind: .coin(minimumOnChainConfirmations: 30),
            name: "Ethereum",
            precision: 18,
            products: AssetModelProduct.allCases,
            logoPngUrl: nil,
            spotColor: "473BCB",
            sortIndex: 2
        )
    }

    public static var stellar: AssetModel {
        AssetModel(
            code: "XLM",
            displayCode: "XLM",
            kind: .coin(minimumOnChainConfirmations: 3),
            name: "Stellar",
            precision: 7,
            products: AssetModelProduct.allCases,
            logoPngUrl: nil,
            spotColor: "000000",
            sortIndex: 4
        )
    }
}
