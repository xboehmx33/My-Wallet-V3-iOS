// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

public struct CustodialTransferFee {
    let fee: [CurrencyType: MoneyValue]
    let minimumAmount: [CurrencyType: MoneyValue]

    public init(
        fee: [CurrencyType: MoneyValue],
        minimumAmount: [CurrencyType: MoneyValue]
    ) {
        self.fee = fee
        self.minimumAmount = minimumAmount
    }

    public subscript(fee currency: CurrencyType) -> MoneyValue {
        fee[currency] ?? .zero(currency: currency)
    }

    public subscript(minimumAmount currency: CurrencyType) -> MoneyValue {
        minimumAmount[currency] ?? .zero(currency: currency)
    }
}
