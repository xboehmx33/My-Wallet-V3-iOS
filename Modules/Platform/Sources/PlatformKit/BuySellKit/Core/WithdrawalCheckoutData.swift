// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

public struct WithdrawalCheckoutData: Equatable {
    public let currency: FiatCurrency
    public let beneficiary: Beneficiary
    public let amount: FiatValue
    public let fee: FiatValue

    public init(
        currency: FiatCurrency,
        beneficiary: Beneficiary,
        amount: FiatValue,
        fee: FiatValue
    ) {
        self.currency = currency
        self.beneficiary = beneficiary
        self.amount = amount
        self.fee = fee
    }
}
