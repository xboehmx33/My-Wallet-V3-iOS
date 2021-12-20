// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import PlatformKit

public enum InterestAccountRateError: Error {
    case networkError(Error)
}

public protocol InterestAccountRateRepositoryAPI: AnyObject {

    /// Fetches `[InterestAccountRate]` for all currencies
    func fetchAllInterestAccountRates()
        -> AnyPublisher<[InterestAccountRate], InterestAccountRateError>

    /// Fetches the current `InterestAccountRate` for a given CryptoCurrency.
    /// - Parameter currency: CryptoCurrency
    func fetchInterestAccountRateForCryptoCurrency(
        _ currency: CryptoCurrency
    ) -> AnyPublisher<InterestAccountRate, InterestAccountRateError>
}
