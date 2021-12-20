// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureInterestDomain
import MoneyKit
import PlatformKit

extension CustodialAccountBalanceStates {

    // MARK: - Init

    init(response: SavingsAccountBalanceResponse) {
        let balances = response.balances
            .reduce(into: [CurrencyType: CustodialAccountBalanceState]()) { result, item in
                guard let cryptoCurrency = CryptoCurrency(code: item.key) else {
                    return
                }
                guard let accountBalance = CustodialAccountBalance(
                    currency: cryptoCurrency.currencyType,
                    response: item.value
                ) else {
                    return
                }
                result[cryptoCurrency.currencyType] = .present(accountBalance)
            }
        self = .init(balances: balances)
    }
}

extension CustodialAccountBalance {

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
