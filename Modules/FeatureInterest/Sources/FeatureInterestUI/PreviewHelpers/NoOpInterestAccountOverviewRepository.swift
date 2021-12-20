// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureInterestDomain
import MoneyKit
import PlatformKit

final class NoOpInterestAccountOverviewRepository: InterestAccountOverviewRepositoryAPI {
    func fetchInterestAccountOverviewListForFiatCurrency(
        _ fiatCurrency: FiatCurrency
    ) -> AnyPublisher<[InterestAccountOverview], InterestAccountOverviewError> {
        Empty().eraseToAnyPublisher()
    }
}
