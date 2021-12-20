// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureTransactionDomain
import MoneyKit
import NabuNetworkError
import PlatformKit

protocol OrderCreationClientAPI {

    func create(
        direction: OrderDirection,
        quoteIdentifier: String,
        volume: MoneyValue,
        destinationAddress: String?,
        refundAddress: String?
    ) -> AnyPublisher<SwapActivityItemEvent, NabuNetworkError>

    func create(
        direction: OrderDirection,
        quoteIdentifier: String,
        volume: MoneyValue,
        ccy: String?
    ) -> AnyPublisher<SwapActivityItemEvent, NabuNetworkError>
}

protocol OrderUpdateClientAPI {

    func updateOrder(
        with transactionId: String,
        success: Bool
    ) -> AnyPublisher<Void, NabuNetworkError>
}
