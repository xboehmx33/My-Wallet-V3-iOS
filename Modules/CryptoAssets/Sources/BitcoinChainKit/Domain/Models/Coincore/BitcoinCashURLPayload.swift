// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

/// Encapsulates the payload of a "bitcoincash:" URL payload
struct BitcoinCashURLPayload: BIP21URI {

    static let scheme: String = "bitcoincash"

    let address: String
    let amount: String?
    let cryptoCurrency: CryptoCurrency = .coin(.bitcoinCash)
    let includeScheme: Bool

    init(address: String, amount: String?) {
        self.init(address: address, amount: amount, includeScheme: false)
    }

    init(address: String, amount: String?, includeScheme: Bool) {
        self.address = address
        self.amount = amount
        self.includeScheme = includeScheme
    }
}
