// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

extension MoneyValuePair {

    /// Returns the inversed money value pair.
    ///
    /// For a pair with base `1 BTC` and quote `50,000 USD`, this will return a pair with base `1 USD` and quote `1 / 50,000 BTC`.
    public var inverseQuote: MoneyValuePair {
        guard !base.isZero, !quote.isZero else {
            return .zero(
                baseCurrency: quote.currency,
                quoteCurrency: base.currency
            )
        }

        return MoneyValuePair(
            base: .one(currency: quote.currency),
            quote: base.convert(usingInverse: quote, currencyType: base.currency)
        )
    }
}
