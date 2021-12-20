// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit

public protocol InterestAccountEligibilityRepositoryAPI {

    /// Fetches all interest eligible currencies
    func fetchAllInterestEnabledCurrencies()
        -> AnyPublisher<[CurrencyType], InterestAccountEligibilityError>

    /// Fetches all `InterestAccountEligibility` objects.
    func fetchAllInterestAccountEligibility()
        -> AnyPublisher<[InterestAccountEligibility], InterestAccountEligibilityError>

    /// Fetches an `InterestAccountEligibility` object for a given
    /// currency code.
    /// - Parameter code: A currency code
    func fetchInterestAccountEligibilityForCurrencyCode(
        _ code: String
    ) -> AnyPublisher<InterestAccountEligibility, InterestAccountEligibilityError>
}
