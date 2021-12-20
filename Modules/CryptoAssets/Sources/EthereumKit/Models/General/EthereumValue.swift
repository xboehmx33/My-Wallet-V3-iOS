// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit

enum EthereumValueError: Error {
    case invalidCryptoValue
}

public struct EthereumValue: CryptoMoney {

    public let currencyType: CurrencyType = .crypto(.coin(.ethereum))

    public let currency: CryptoCurrency = .coin(.ethereum)

    public var amount: BigInt {
        crypto.amount
    }

    private let crypto: CryptoMoney

    public init(crypto: CryptoMoney) throws {
        guard crypto.currencyType == .coin(.ethereum) else {
            throw EthereumValueError.invalidCryptoValue
        }
        self.crypto = crypto
    }
}
