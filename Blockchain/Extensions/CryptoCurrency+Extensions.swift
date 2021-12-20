// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import PlatformUIKit
import ToolKit

extension CryptoCurrency {
    /// The legacy representation of `CryptoCurrency`
    var legacy: LegacyAssetType {
        switch self {
        case .coin(.bitcoin):
            return .bitcoin
        case .coin(.bitcoinCash):
            return .bitcoinCash
        default:
            impossible()
        }
    }
}

extension LegacyAssetType {
    var cryptoCurrency: CryptoCurrency {
        switch self {
        case .bitcoin:
            return .coin(.bitcoin)
        case .bitcoinCash:
            return .coin(.bitcoinCash)
        }
    }

    var nonCustodialCoinCode: NonCustodialCoinCode {
        switch self {
        case .bitcoin:
            return .bitcoin
        case .bitcoinCash:
            return .bitcoinCash
        }
    }
}
