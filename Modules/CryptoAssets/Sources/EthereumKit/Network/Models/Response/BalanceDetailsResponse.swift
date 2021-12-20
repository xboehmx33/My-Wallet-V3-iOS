// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit

public struct BalanceDetailsResponse: Decodable {
    let balance: String
    let nonce: UInt64

    var cryptoValue: CryptoValue {
        .create(minor: balance, currency: .coin(.ethereum)) ?? .zero(currency: .coin(.ethereum))
    }
}
