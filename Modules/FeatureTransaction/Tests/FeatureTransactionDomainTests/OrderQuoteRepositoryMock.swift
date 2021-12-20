// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
@testable import FeatureTransactionDomain
import MoneyKit
import NabuNetworkError
import PlatformKit

final class OrderQuoteRepositoryMock: FeatureTransactionDomain.OrderQuoteRepositoryAPI {

    var underlying: EnabledCurrenciesServiceAPI!

    var latestQuote: AnyPublisher<OrderQuotePayload, NabuNetworkError> {
        .just(OrderQuotePayload.btc_eth_quote_response)
    }

    func fetchQuote(
        direction: OrderDirection,
        sourceCurrencyType: CurrencyType,
        destinationCurrencyType: CurrencyType
    ) -> AnyPublisher<OrderQuotePayload, NabuNetworkError> {
        latestQuote
    }

    private let btc_eth_quote_response = Data("""
    {
      "id": "039267ab-de16-4093-8cdf-a7ea1c732dbd",
      "product": "BROKERAGE",
      "pair": "BTC-ETH",
      "quote": {
        "currencyPair": "BTC-ETH",
        "priceTiers": [
          {
            "volume": "286",
            "price": "34936084430000000000",
            "marginPrice": "34936084430000000000"
          },
          {
            "volume": "2862782",
            "price": "34931056570000000000",
            "marginPrice": "34931056570000000000"
          }
        ]
      },
      "networkFee": "0",
      "staticFee": "0",
      "sampleDepositAddress": "1BitcoinEaterAddressDontSendf59kuE",
      "expiresAt": "2021-01-01T12:01:59.000Z",
      "createdAt": "2020-12-31T23:59:59.000Z",
      "updatedAt": "2020-12-31T23:59:59.000Z"
    }
    """.utf8)
}

extension OrderQuotePayload {
    static let btc_eth_quote_response = OrderQuotePayload(
        identifier: "",
        pair: OrderPair.btc_eth,
        quote: .btc_eth_quote,
        networkFee: .zero(currency: .crypto(.coin(.bitcoin))),
        staticFee: .zero(currency: .crypto(.coin(.bitcoin))),
        sampleDepositAddress: "",
        expiresAt: Date(),
        createdAt: Date(),
        updatedAt: Date()
    )
}

extension OrderPair {
    static let btc_eth = OrderPair(
        sourceCurrencyType: .crypto(.coin(.bitcoin)),
        destinationCurrencyType: .crypto(.coin(.ethereum))
    )
}

extension OrderQuote {
    static let btc_eth_quote: OrderQuote = .init(
        pair: .init(sourceCurrencyType: .crypto(.coin(.bitcoin)), destinationCurrencyType: .crypto(.coin(.bitcoin))),
        priceTiers: [
            .init(volume: "286", price: "34936084430000000000", marginPrice: "34936084430000000000"),
            .init(volume: "2862782", price: "34931056570000000000", marginPrice: "34931056570000000000")
        ]
    )
    static let btc_eth_quote_empty: OrderQuote = .init(pair: .btc_eth, priceTiers: [])
}
