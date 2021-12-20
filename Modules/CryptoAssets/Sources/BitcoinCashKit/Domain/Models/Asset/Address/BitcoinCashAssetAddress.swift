// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

public struct BitcoinCashAssetAddress: AssetAddress, Importable, Hashable {

    public let isImported: Bool
    public let publicKey: String
    public let cryptoCurrency: CryptoCurrency = .coin(.bitcoinCash)

    public init(isImported: Bool = false, publicKey: String) {
        self.isImported = isImported
        self.publicKey = publicKey
    }
}
