// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError
import PlatformKit

protocol InterestActivityItemEventClientAPI {
    func fetchInterestActivityItemEventsForCryptoCurrency(
        _ cryptoCurrency: CryptoCurrency
    ) -> AnyPublisher<InterestActivityResponse, NabuNetworkError>
}
