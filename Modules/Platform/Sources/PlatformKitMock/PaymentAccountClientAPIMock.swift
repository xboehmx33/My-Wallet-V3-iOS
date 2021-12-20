// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError
@testable import PlatformKit

class SimpleBuyPaymentAccountClientAPIMock: PaymentAccountClientAPI {
    var mockResponse: PaymentAccountResponse! = .mock(with: .GBP, agent: .fullMock)

    func paymentAccount(
        for currency: FiatCurrency
    ) -> AnyPublisher<PlatformKit.PaymentAccount.Response, NabuNetworkError> {
        Just(mockResponse)
            .setFailureType(to: NabuNetworkError.self)
            .eraseToAnyPublisher()
    }
}
