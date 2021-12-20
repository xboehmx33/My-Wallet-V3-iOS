// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

extension CustodialAccountBalance {

    init?(
        currency: CurrencyType,
        response: InterestAccountBalanceDetails
    ) {
        guard let balance = response.balance else { return nil }
        let zero: MoneyValue = .zero(currency: currency)
        self.init(
            currency: currency,
            available: MoneyValue.create(minor: balance, currency: currency) ?? zero,
            withdrawable: zero,
            pending: zero
        )
    }

    init?(
        currency: CurrencyType,
        response: SavingsAccountBalanceDetails
    ) {
        guard let balance = response.balance else { return nil }
        let zero: MoneyValue = .zero(currency: currency)
        self.init(
            currency: currency,
            available: MoneyValue.create(minor: balance, currency: currency) ?? zero,
            withdrawable: zero,
            pending: zero
        )
    }
}
