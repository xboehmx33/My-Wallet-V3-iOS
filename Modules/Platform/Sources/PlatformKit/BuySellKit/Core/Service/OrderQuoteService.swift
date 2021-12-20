// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import NabuNetworkError
import RxSwift
import ToolKit

public enum Profile: String, Encodable {
    case simpleBuy = "SIMPLEBUY"
    case simpleTrade = "SIMPLETRADE"
    case swapFromUserKey = "SWAP_FROM_USERKEY"
    case swapInternal = "SWAP_INTERNAL"
    case swapOnChain = "SWAP_ON_CHAIN"
}

public struct QuoteQuery {

    /// The type of quote
    let profile: Profile

    /// The source currency, fiat or crypto
    let sourceCurrency: Currency

    /// The destination curency, fiat or crypto
    let destinationCurrency: Currency

    /// The source amount, fiat or crypto
    let amount: MoneyValue

    /// The payment method if relevant profile is chosen
    let paymentMethod: PaymentMethodPayloadType?

    /// The payment method Id if the method is bank transfer
    let paymentMethodId: String?

    public init(
        profile: Profile,
        sourceCurrency: Currency,
        destinationCurrency: Currency,
        amount: MoneyValue,
        paymentMethod: PaymentMethodPayloadType?,
        paymentMethodId: String?
    ) {
        self.profile = profile
        self.sourceCurrency = sourceCurrency
        self.destinationCurrency = destinationCurrency
        self.amount = amount
        self.paymentMethod = paymentMethod
        self.paymentMethodId = paymentMethodId
    }
}

/// Used to convert the user input into an actual quote with fee (takes a fiat amount)
public protocol OrderQuoteServiceAPI: AnyObject {

    func getQuote(
        query: QuoteQuery
    ) -> Single<Quote>
}

final class OrderQuoteService: OrderQuoteServiceAPI {

    // MARK: - Properties

    private let client: QuoteClientAPI
    private let featureFlagsService: FeatureFlagsServiceAPI

    // MARK: - Setup

    init(
        client: QuoteClientAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        self.client = client
        self.featureFlagsService = featureFlagsService
    }

    // MARK: - API

    func getQuote(
        query: QuoteQuery
    ) -> Single<Quote> {
        featureFlagsService
            .isEnabled(.remote(.newQuoteForSimpleBuy))
            .asSingle()
            .flatMap { [getOldQuote, getNewQuote] isEnabled in
                guard isEnabled else {
                    return getOldQuote(query)
                }
                return getNewQuote(query)
            }
    }

    @available(*, deprecated, message: "This should not be used when new quote model becomes stable")
    private func getOldQuote(
        query: QuoteQuery
    ) -> Single<Quote> {
        client
            .getOldQuote(for: .buy, to: query.destinationCurrency, amount: query.amount)
            .asSingle()
            .map {
                try Quote(
                    sourceCurrency: query.sourceCurrency,
                    destinationCurrency: query.destinationCurrency,
                    value: query.amount,
                    response: $0
                )
            }
    }

    private func getNewQuote(
        query: QuoteQuery
    ) -> Single<Quote> {
        client
            .getQuote(queryRequest: QuoteQueryRequest(from: query))
            .asSingle()
            .map {
                try Quote(
                    sourceCurrency: query.sourceCurrency,
                    destinationCurrency: query.destinationCurrency,
                    value: query.amount,
                    response: $0
                )
            }
    }
}
