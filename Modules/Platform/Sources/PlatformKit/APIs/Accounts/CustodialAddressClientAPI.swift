// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError

protocol CustodialPaymentAccountClientAPI {

    func custodialPaymentAccount(
        for cryptoCurrency: CryptoCurrency
    ) -> AnyPublisher<PaymentAccount.Response, NabuNetworkError>
}
