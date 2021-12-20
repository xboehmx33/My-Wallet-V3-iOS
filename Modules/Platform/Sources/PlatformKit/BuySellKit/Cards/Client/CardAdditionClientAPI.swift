// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import NabuNetworkError

public protocol CardAdditionClientAPI: AnyObject {

    func add(
        for currency: String,
        email: String,
        billingAddress: CardPayload.BillingAddress,
        paymentMethodTokens: [String: String]
    ) -> AnyPublisher<CardPayload, NabuNetworkError>
}
