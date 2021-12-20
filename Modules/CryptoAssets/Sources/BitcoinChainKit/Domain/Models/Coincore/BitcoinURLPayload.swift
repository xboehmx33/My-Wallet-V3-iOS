// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

/// Encapsulates the payload of a "bitcoin:" URL payload
public struct BitcoinURLPayload: BIP21URI {

    public static let scheme: String = "bitcoin"

    public let address: String
    public let amount: String?
    public let cryptoCurrency: CryptoCurrency = .coin(.bitcoin)
    public let includeScheme: Bool

    public init(address: String, amount: String?) {
        self.init(address: address, amount: amount, includeScheme: false)
    }

    init(address: String, amount: String?, includeScheme: Bool) {
        self.address = address
        self.amount = amount
        self.includeScheme = includeScheme
    }
}
