// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

/// A historical price series in fiat, for one crypto currency, in a specific time range.
public struct HistoricalPriceSeries {

    // MARK: - Public Properties

    /// The associated crypto currency.
    public let currency: CryptoCurrency

    /// The array of quoted prices.
    public let prices: [PriceQuoteAtTime]

    /// The numeric difference, in major units, between the last price and the first price in the series.
    public let fiatChange: Decimal

    /// The relative difference between the last price and the first price in the series.
    public let delta: Double

    /// The percentage difference between the last price and the first price in the series.
    public let deltaPercentage: Double

    // MARK: - Setup

    /// Creates a historical price series.
    ///
    /// - Parameters:
    ///   - currency: The crypto currency associated with `prices`.
    ///   - prices:   An array of quoted prices.
    public init(currency: CryptoCurrency, prices: [PriceQuoteAtTime]) {
        if let first = prices.first, let latest = prices.last {
            let fiatChange = latest.moneyValue.displayMajorValue - first.moneyValue.displayMajorValue
            let delta = fiatChange.doubleValue / first.moneyValue.displayMajorValue.doubleValue
            self.init(
                currency: currency,
                prices: prices,
                fiatChange: fiatChange,
                delta: delta,
                deltaPercentage: delta * 100
            )
        } else {
            self.init(currency: currency, prices: [], fiatChange: 0, delta: 0, deltaPercentage: 0)
        }
    }

    private init(
        currency: CryptoCurrency,
        prices: [PriceQuoteAtTime],
        fiatChange: Decimal,
        delta: Double,
        deltaPercentage: Double
    ) {
        self.currency = currency
        self.delta = delta
        self.deltaPercentage = deltaPercentage
        self.prices = prices
        self.fiatChange = fiatChange
    }
}
