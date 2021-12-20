// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Foundation

/// A crypto currency, representing a digital asset.
public enum CryptoCurrency: Currency, Hashable, Codable, Comparable, CustomDebugStringConvertible, Equatable {

    /// A coin crypto currency.
    case coin(AssetModel)

    /// A coin crypto currency.
    case celoToken(AssetModel)

    /// An Ethereum ERC-20 crypto currency.
    case erc20(AssetModel)

    /// Creates a crypto currency.
    ///
    /// If `code` is invalid, this initializer returns `nil`.
    ///
    /// - Parameters:
    ///   - code:                     A crypto currency code.
    ///   - enabledCurrenciesService: An enabled currencies service.
    public init?(code: String, enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve()) {
        guard let cryptoCurrency = enabledCurrenciesService.allEnabledCryptoCurrencies
            .first(where: { $0.code == code })
        else {
            return nil
        }

        self = cryptoCurrency
    }

    /// Creates an ERC-20 crypto currency.
    ///
    /// If `erc20Address` is invalid, this initializer returns `nil`.
    ///
    /// - Parameters:
    ///   - erc20Address:             An ERC-20 contract address.
    ///   - enabledCurrenciesService: An enabled currencies service.
    public init?(erc20Address: String, enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve()) {
        guard let cryptoCurrency = enabledCurrenciesService.allEnabledCryptoCurrencies.first(where: { currency in
            switch currency {
            case .coin, .celoToken:
                return false
            case .erc20(let model):
                switch model.kind {
                case .erc20(let contractAddress):
                    return contractAddress.caseInsensitiveCompare(erc20Address) == .orderedSame
                default:
                    return false
                }
            }
        }) else {
            return nil
        }
        self = cryptoCurrency
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        guard let cryptoCurrency = CryptoCurrency(code: stringValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported currency \(stringValue)"
            )
        }
        self = cryptoCurrency
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(code)
    }

    public var debugDescription: String {
        "CryptoCurrency.\(code)"
    }

    /// Whether the crypto currency is a coin asset.
    public var isCoin: Bool {
        assetModel.kind.isCoin
    }

    /// Whether the crypto currency is an Ethereum ERC-20 asset.
    public var isERC20: Bool {
        assetModel.kind.isERC20
    }

    /// Whether the crypto currency is an Celo Token asset.
    public var isCeloToken: Bool {
        assetModel.kind.isCeloToken
    }

    /// The underlying asset of the crypto currency.
    public var assetModel: AssetModel {
        switch self {
        case .coin(let model),
             .erc20(let model),
             .celoToken(let model):
            return model
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(assetModel)
    }

    public func supports(product: AssetModelProduct) -> Bool {
        assetModel.supports(product: product)
    }
}

// MARK: - Currency

extension CryptoCurrency {

    public static let maxDisplayPrecision: Int = 8

    public var name: String {
        assetModel.name
    }

    public var code: String {
        assetModel.code
    }

    public var displayCode: String {
        assetModel.displayCode
    }

    public var displaySymbol: String { displayCode }

    public var precision: Int {
        assetModel.precision
    }

    public var displayPrecision: Int {
        min(CryptoCurrency.maxDisplayPrecision, precision)
    }

    public static func < (lhs: CryptoCurrency, rhs: CryptoCurrency) -> Bool {
        lhs.assetModel.sortIndex < rhs.assetModel.sortIndex
    }

    public static func == (lhs: CryptoCurrency, rhs: CryptoCurrency) -> Bool {
        lhs.assetModel == rhs.assetModel
    }
}
