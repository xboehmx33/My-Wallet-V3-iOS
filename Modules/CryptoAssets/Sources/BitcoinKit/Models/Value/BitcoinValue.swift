// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit

public enum BitcoinValueError: Error {
    case invalidCryptoValue
}

public struct BitcoinValue: CryptoMoney {

    public let currencyType: CurrencyType = .crypto(.coin(.bitcoin))

    public let currency: CryptoCurrency = .coin(.bitcoin)

    public var amount: BigInt {
        crypto.amount
    }

    public static let zero = BitcoinValue(satoshis: 0)

    private let crypto: CryptoMoney

    public init(crypto: CryptoMoney) throws {
        guard crypto.currencyType == .coin(.bitcoin) else {
            throw BitcoinValueError.invalidCryptoValue
        }
        self.crypto = crypto
    }

    public init(satoshis: Decimal) {
        crypto = CryptoValue.create(minor: satoshis, currency: .coin(.bitcoin))
    }
}

extension BitcoinValue: Equatable {
    public static func == (lhs: BitcoinValue, rhs: BitcoinValue) -> Bool {
        lhs.amount == rhs.amount
    }
}
