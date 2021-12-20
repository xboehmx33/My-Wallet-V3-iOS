// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NetworkError
import PlatformKit

public final class PriceServiceMock: PriceServiceAPI {

    public struct StubbedResults {
        public var moneyValuePair = MoneyValuePair(
            base: .one(currency: .coin(.bitcoin)),
            quote: MoneyValue(amount: 10000000, currency: .fiat(.USD))
        )
        public var historicalPriceSeries = HistoricalPriceSeries(
            currency: .coin(.bitcoin),
            prices: [
                PriceQuoteAtTime(
                    timestamp: Date(),
                    moneyValue: MoneyValue(amount: 10000000, currency: .fiat(.USD))
                )
            ]
        )
        public var priceQuoteAtTime = PriceQuoteAtTime(
            timestamp: Date(),
            moneyValue: MoneyValue(amount: 10000000, currency: .fiat(.USD))
        )
    }

    public var stubbedResults = StubbedResults()

    public init() {}

    public func moneyValuePair(
        fiatValue: FiatValue,
        cryptoCurrency: CryptoCurrency,
        usesFiatAsBase: Bool
    ) -> AnyPublisher<MoneyValuePair, PriceServiceError> {
        .just(stubbedResults.moneyValuePair)
    }

    public func price(
        of base: Currency,
        in quote: Currency
    ) -> AnyPublisher<PriceQuoteAtTime, PriceServiceError> {
        .just(stubbedResults.priceQuoteAtTime)
    }

    public func price(
        of base: Currency,
        in quote: Currency,
        at time: PriceTime
    ) -> AnyPublisher<PriceQuoteAtTime, PriceServiceError> {
        .just(stubbedResults.priceQuoteAtTime)
    }

    public func priceSeries(
        of baseCurrency: CryptoCurrency,
        in quoteCurrency: FiatCurrency,
        within window: PriceWindow
    ) -> AnyPublisher<HistoricalPriceSeries, PriceServiceError> {
        .just(stubbedResults.historicalPriceSeries)
    }
}
