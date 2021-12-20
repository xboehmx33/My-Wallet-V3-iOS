// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError

protocol SuggestedAmountsClientAPI: AnyObject {

    func suggestedAmounts(
        for currency: FiatCurrency
    ) -> AnyPublisher<SuggestedAmountsResponse, NabuNetworkError>
}
