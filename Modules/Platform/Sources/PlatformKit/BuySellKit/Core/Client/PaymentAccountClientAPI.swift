// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError

protocol PaymentAccountClientAPI: AnyObject {

    /// Fetch the Payment Account information for the given currency.
    func paymentAccount(
        for currency: FiatCurrency
    ) -> AnyPublisher<PlatformKit.PaymentAccount.Response, NabuNetworkError>
}
