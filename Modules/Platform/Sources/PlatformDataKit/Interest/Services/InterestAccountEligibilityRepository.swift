// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import PlatformKit

final class InterestAccountEligibilityRepository: InterestAccountEligibilityRepositoryAPI {

    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI
    private let client: InterestAccountEligibilityClientAPI

    init(
        client: InterestAccountEligibilityClientAPI = resolve(),
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve()
    ) {
        self.enabledCurrenciesService = enabledCurrenciesService
        self.client = client
    }

    func fetchAllInterestEnabledCurrencies()
        -> AnyPublisher<[CurrencyType], InterestAccountEligibilityError>
    {
        client
            .fetchInterestEnabledCurrenciesResponse()
            .mapError(InterestAccountEligibilityError.networkError)
            .map(\.instruments)
            .map { currencyCodes in
                currencyCodes.compactMap { try? CurrencyType(code: $0) }
            }
            .eraseToAnyPublisher()
    }

    func fetchAllInterestAccountEligibility()
        -> AnyPublisher<[InterestAccountEligibility], InterestAccountEligibilityError>
    {
        fetchInterestAccountEligibilities()
            .eraseToAnyPublisher()
    }

    func fetchInterestAccountEligibilityForCurrencyCode(
        _ code: String
    ) -> AnyPublisher<InterestAccountEligibility, InterestAccountEligibilityError> {
        fetchInterestAccountEligibilities()
            .map { $0.filter { $0.currencyType.code == code } }
            .compactMap(\.first)
            .eraseToAnyPublisher()
    }

    private func fetchInterestAccountEligibilities()
        -> AnyPublisher<[InterestAccountEligibility], InterestAccountEligibilityError>
    {
        client
            .fetchInterestAccountEligibilityResponse()
            .mapError(InterestAccountEligibilityError.networkError)
            .zip(fetchAllInterestEnabledCurrencies())
            .map { eligbilityResponse, enabledCurrencies -> [InterestAccountEligibility] in
                enabledCurrencies
                    .map { asset -> InterestAccountEligibility in
                        guard let eligibility = eligbilityResponse[asset] else {
                            return InterestAccountEligibility.notEligible(currencyType: asset)
                        }
                        return InterestAccountEligibility(currencyType: asset, interestEligibility: eligibility)
                    }
            }
            .eraseToAnyPublisher()
    }
}
