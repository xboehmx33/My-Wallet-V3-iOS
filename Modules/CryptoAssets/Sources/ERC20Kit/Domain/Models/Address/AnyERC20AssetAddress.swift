// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

public struct ERC20AssetAddress: AssetAddress {
    public let publicKey: String
    public let cryptoCurrency: CryptoCurrency

    public init(publicKey: String, cryptoCurrency: CryptoCurrency) {
        self.publicKey = publicKey
        self.cryptoCurrency = cryptoCurrency
    }
}
