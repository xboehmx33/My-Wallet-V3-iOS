// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureTransactionDomain
import MoneyKit
import NabuNetworkError
import PlatformKit
import ToolKit

final class OrderQuoteRepository: OrderQuoteRepositoryAPI {

    // MARK: - Properties

    private let client: CustodialQuoteAPI

    // MARK: - Setup

    init(client: CustodialQuoteAPI = resolve()) {
        self.client = client
    }

    // MARK: - OrderQuoteServiceAPI

    func fetchQuote(
        direction: OrderDirection,
        sourceCurrencyType: CurrencyType,
        destinationCurrencyType: CurrencyType
    ) -> AnyPublisher<OrderQuotePayload, NabuNetworkError> {
        let request = OrderQuoteRequest(
            product: .brokerage,
            direction: direction,
            pair: .init(
                sourceCurrencyType: sourceCurrencyType,
                destinationCurrencyType: destinationCurrencyType
            )
        )
        return client.fetchQuoteResponse(with: request)
            .map(OrderQuotePayload.init)
            .eraseToAnyPublisher()
    }
}
