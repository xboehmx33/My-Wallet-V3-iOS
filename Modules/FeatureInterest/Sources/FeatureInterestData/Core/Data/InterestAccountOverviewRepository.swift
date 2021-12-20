// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureInterestDomain
import MoneyKit
import PlatformKit
import ToolKit

final class InterestAccountOverviewRepository: InterestAccountOverviewRepositoryAPI {

    // MARK: - Private Properties

    private let interestAccountEligibilityRepository: InterestAccountEligibilityRepositoryAPI
    private let interestAccountRateRepository: InterestAccountRateRepositoryAPI
    private let interestAccountBalanceRepository: InterestAccountBalanceRepositoryAPI
    private let interestAccountLimitsRepository: InterestAccountLimitsRepositoryAPI

    // MARK: - Init

    init(
        interestAccountEligibilityRepository: InterestAccountEligibilityRepositoryAPI = resolve(),
        interestAccountRateRepository: InterestAccountRateRepositoryAPI = resolve(),
        interestAccountBalanceRepository: InterestAccountBalanceRepositoryAPI = resolve(),
        interestAccountLimitsRepository: InterestAccountLimitsRepositoryAPI = resolve()
    ) {
        self.interestAccountRateRepository = interestAccountRateRepository
        self.interestAccountEligibilityRepository = interestAccountEligibilityRepository
        self.interestAccountBalanceRepository = interestAccountBalanceRepository
        self.interestAccountLimitsRepository = interestAccountLimitsRepository
    }

    // MARK: - InterestAccountOverviewRepositoryAPI

    func fetchInterestAccountOverviewListForFiatCurrency(
        _ fiatCurrency: FiatCurrency
    ) -> AnyPublisher<[InterestAccountOverview], InterestAccountOverviewError> {
        Publishers.Zip4(
            interestAccountEligibilityRepository
                .fetchAllInterestAccountEligibility()
                .mapError(InterestAccountOverviewError.networkError),
            interestAccountRateRepository
                .fetchAllInterestAccountRates()
                .mapError(InterestAccountOverviewError.networkError),
            interestAccountBalanceRepository
                .fetchInterestAccountsBalance(fiatCurrency: fiatCurrency)
                .mapError(InterestAccountOverviewError.networkError),
            interestAccountLimitsRepository
                .fetchInterestAccountLimitsForAllAssets(fiatCurrency)
                .mapError(InterestAccountOverviewError.networkError)
        )
        .map { accountEligibilities, accountRates, accountBalances, limits -> [InterestAccountOverview] in
            accountEligibilities
                .compactMap { accountEligibility -> InterestAccountOverview? in
                    let currencyType = accountEligibility.currencyType
                    let code = accountEligibility.currencyType.code
                    let rate = accountRates
                        .first(where: { .crypto($0.cryptoCurrency) == currencyType })
                    let balance = accountBalances.balances[code]
                    let accountLimits = limits
                        .first(where: { .crypto($0.cryptoCurrency) == currencyType })

                    guard let interestAccountLimits = accountLimits else {
                        Logger.shared.debug(
                            "Interest account limits unavailable for currency code: \(accountEligibility.currencyType.code)"
                        )
                        return nil
                    }

                    guard let interestAccountRate = rate else {
                        Logger.shared.debug(
                            "Interest rate unavailable for currency code: \(accountEligibility.currencyType.code)"
                        )
                        return nil
                    }
                    return InterestAccountOverview(
                        interestAccountEligibility: accountEligibility,
                        interestAccountRate: interestAccountRate,
                        interestAccountLimits: interestAccountLimits,
                        balanceDetails: balance
                    )
                }
        }
        .eraseToAnyPublisher()
    }
}
