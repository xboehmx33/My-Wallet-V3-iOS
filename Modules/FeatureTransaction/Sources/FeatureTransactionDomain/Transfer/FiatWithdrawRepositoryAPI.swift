// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError

public protocol FiatWithdrawRepositoryAPI {

    func createWithdrawOrder(
        id: String,
        amount: MoneyValue
    ) -> AnyPublisher<Void, NabuNetworkError>
}
