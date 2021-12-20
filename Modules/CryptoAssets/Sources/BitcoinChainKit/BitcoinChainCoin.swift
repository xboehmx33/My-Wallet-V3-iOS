// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit

public enum BitcoinChainCoin: String {
    case bitcoin = "BTC"
    case bitcoinCash = "BCH"

    public var cryptoCurrency: CryptoCurrency {
        switch self {
        case .bitcoin:
            return .coin(.bitcoin)
        case .bitcoinCash:
            return .coin(.bitcoinCash)
        }
    }

    public var maximumSupply: BigInt {
        switch self {
        case .bitcoin,
             .bitcoinCash:
            return 2100000000000000
        }
    }

    public var dust: BigInt {
        switch self {
        case .bitcoin,
             .bitcoinCash:
            return 546
        }
    }
}

public protocol BitcoinChainToken {
    static var coin: BitcoinChainCoin { get }
}

public struct BitcoinToken: BitcoinChainToken {
    public static let coin: BitcoinChainCoin = .bitcoin
}

public struct BitcoinCashToken: BitcoinChainToken {
    public static let coin: BitcoinChainCoin = .bitcoinCash
}
