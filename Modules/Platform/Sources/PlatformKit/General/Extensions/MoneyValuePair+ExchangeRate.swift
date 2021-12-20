// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

extension MoneyValuePair {

    /// Returns a new `MoneyValuePair` instance intended to get the FX quote from an existing quote.
    /// This means that given a FX quote like 3 BTC = 150,000 USD, this will return a new quote => 1 BTC  = 150,000 / 3 BTC.
    public var exchangeRate: MoneyValuePair {
        // `try`s are disabled here as this operation can never fail.
        // If it failed, it would be a developer error and thus it's better to crash.
        guard !base.isZero, !quote.isZero else {
            return MoneyValuePair.zero(baseCurrency: base.currency, quoteCurrency: quote.currency)
        }

        // swiftlint:disable:next force_try
        return try! MoneyValuePair(
            base: .one(currency: base.currency),
            quote: quote.convert(usingInverse: base, currencyType: quote.currency)
        )
    }

    /// Returns a new `MoneyValuePair` instance intended to get the inverse FX quote from an existing quote.
    /// This means that given a FX quote like 1 BTC = 50,000 USD, this will return a new quote => 1 USD  = 1 / 50,000 BTC.
    public var inverseExchangeRate: MoneyValuePair {
        // `try`s are disabled here as this operation can never fail.
        // If it failed, it would be a developer error and thus it's better to crash.
        guard !base.isZero, !quote.isZero else {
            return MoneyValuePair.zero(baseCurrency: quote.currency, quoteCurrency: base.currency)
        }

        // swiftlint:disable:next force_try
        return try! MoneyValuePair(
            base: .one(currency: quote.currencyType),
            quote: base.convert(usingInverse: quote, currencyType: base.currencyType)
        )
    }
}
