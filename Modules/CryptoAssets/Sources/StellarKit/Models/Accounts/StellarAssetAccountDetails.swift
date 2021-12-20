// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import stellarsdk

public struct StellarAccountDetails {
    public let account: StellarAssetAccount
    public let balance: CryptoValue
    public let actionableBalance: CryptoValue
}

// MARK: Extension

extension StellarAccountDetails {
    public static func unfunded(accountID: String) -> StellarAccountDetails {
        let account = StellarAssetAccount(
            accountAddress: accountID,
            name: CryptoCurrency.coin(.stellar).defaultWalletName,
            description: CryptoCurrency.coin(.stellar).defaultWalletName,
            sequence: 0,
            subentryCount: 0
        )

        return StellarAccountDetails(
            account: account,
            balance: .zero(currency: .coin(.stellar)),
            actionableBalance: .zero(currency: .coin(.stellar))
        )
    }
}
