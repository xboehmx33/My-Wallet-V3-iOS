// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureInterestDomain
import MoneyKit
import PlatformKit

final class NoOpInterestAccountBalanceRepository: InterestAccountBalanceRepositoryAPI {
    func fetchInterestAccountsBalance(
        fiatCurrency: FiatCurrency
    ) -> AnyPublisher<InterestAccountBalances, InterestAccountBalanceRepositoryError> {
        Empty().eraseToAnyPublisher()
    }

    func invalidateAccountBalanceCacheWithKey(_ fiatCurrency: FiatCurrency) {
        // no-op
    }
}
