// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import NabuNetworkError

public protocol SupportedPairsServiceAPI: AnyObject {

    /// Fetches `pairs` using the specified filter
    func fetchPairs(for option: SupportedPairsFilterOption) -> AnyPublisher<SupportedPairs, NabuNetworkError>

    /// Fetches a list of supported fiat currencies for trading
    func fetchSupportedTradingCurrencies() -> AnyPublisher<Set<FiatCurrency>, NabuNetworkError>

    /// Fetches a list of supported crypto currencies for trading
    func fetchSupportedTradingCryptoCurrencies() -> AnyPublisher<[CryptoCurrency], NabuNetworkError>
}

final class SupportedPairsService: SupportedPairsServiceAPI {

    // MARK: - Injected

    private let client: SupportedPairsClientAPI

    // MARK: - Setup

    init(client: SupportedPairsClientAPI = resolve()) {
        self.client = client
    }

    // MARK: - SupportedPairsServiceAPI

    func fetchPairs(for option: SupportedPairsFilterOption) -> AnyPublisher<SupportedPairs, NabuNetworkError> {
        client.supportedPairs(with: option)
            .map { SupportedPairs(response: $0, filterOption: option) }
            .eraseToAnyPublisher()
    }

    func fetchSupportedTradingCurrencies() -> AnyPublisher<Set<FiatCurrency>, NabuNetworkError> {
        fetchPairs(for: .all)
            .map(\.fiatCurrencySet)
            .eraseToAnyPublisher()
    }

    func fetchSupportedTradingCryptoCurrencies() -> AnyPublisher<[CryptoCurrency], NabuNetworkError> {
        fetchPairs(for: .all)
            .map(\.cryptoCurrencies)
            .eraseToAnyPublisher()
    }
}
