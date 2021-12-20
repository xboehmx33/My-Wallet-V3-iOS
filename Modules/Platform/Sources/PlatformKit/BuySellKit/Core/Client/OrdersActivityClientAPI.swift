// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError

protocol OrdersActivityClientAPI: AnyObject {

    /// Fetch order activity response
    func activityResponse(
        currency: Currency
    ) -> AnyPublisher<OrdersActivityResponse, NabuNetworkError>
}
