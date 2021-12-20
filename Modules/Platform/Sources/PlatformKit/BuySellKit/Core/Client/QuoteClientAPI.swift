// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError

public struct QuoteQueryRequest: Encodable {

    /// Profile for the quote
    let profile: String

    /// The trading pair for the quote
    let pair: String

    /// The fiat value represented in minor units
    let inputValue: String

    /// The payment method payload type used
    let paymentMethod: String?

    /// The payment method Id for the quote
    let paymentMethodId: String?

    init(from query: QuoteQuery) {
        profile = query.profile.rawValue
        pair = "\(query.sourceCurrency.code)-\(query.destinationCurrency.code)"
        inputValue = query.amount.minorString
        paymentMethod = query.paymentMethod?.rawValue
        paymentMethodId = query.paymentMethodId
    }
}

protocol QuoteClientAPI: AnyObject {

    @available(*, deprecated, message: "This should not be used when new quote model becomes stable")
    func getOldQuote(
        for action: Order.Action,
        to currency: Currency,
        amount: MoneyValue
    ) -> AnyPublisher<OldQuoteResponse, NabuNetworkError>

    /// Get a quote from a simple-buy order. In the future, it will support all sorts of order (buy, sell, swap)
    func getQuote(
        queryRequest: QuoteQueryRequest
    ) -> AnyPublisher<QuoteResponse, NabuNetworkError>
}
