// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

public struct BitcoinAssetAddress: AssetAddress, Importable, Hashable {
    public let isImported: Bool
    public let publicKey: String
    public let cryptoCurrency: CryptoCurrency = .coin(.bitcoin)

    public init(isImported: Bool = false, publicKey: String) {
        self.isImported = isImported
        self.publicKey = publicKey
    }
}
