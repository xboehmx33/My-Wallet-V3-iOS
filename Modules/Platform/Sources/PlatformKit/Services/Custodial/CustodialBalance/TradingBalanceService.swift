// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import RxSwift
import ToolKit

public protocol TradingBalanceServiceAPI: AnyObject {
    var balances: AnyPublisher<CustodialAccountBalanceStates, Never> { get }

    func invalidateTradingAccountBalances()
    func balance(for currencyType: CurrencyType) -> AnyPublisher<CustodialAccountBalanceState, Never>
    func fetchBalances() -> AnyPublisher<CustodialAccountBalanceStates, Never>
}

class TradingBalanceService: TradingBalanceServiceAPI {

    private struct Key: Hashable {}

    // MARK: - Properties

    var balances: AnyPublisher<CustodialAccountBalanceStates, Never> {
        cachedValue.get(key: Key())
            .replaceError(with: .absent)
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private let client: TradingBalanceClientAPI
    private let cachedValue: CachedValueNew<
        Key,
        CustodialAccountBalanceStates,
        Error
    >

    // MARK: - Setup

    init(client: TradingBalanceClientAPI = resolve()) {
        self.client = client

        let cache: AnyCache<Key, CustodialAccountBalanceStates> = InMemoryCache(
            configuration: .onLoginLogoutTransaction(),
            refreshControl: PeriodicCacheRefreshControl(refreshInterval: 60)
        ).eraseToAnyCache()

        cachedValue = CachedValueNew(
            cache: cache,
            fetch: { [client] _ in
                client
                    .balance
                    .map { response in
                        guard let response = response else {
                            return .absent
                        }
                        return CustodialAccountBalanceStates(response: response)
                    }
                    .eraseError()
            }
        )
    }

    // MARK: - Methods

    func invalidateTradingAccountBalances() {
        cachedValue
            .invalidateCacheWithKey(Key())
    }

    func balance(for currencyType: CurrencyType) -> AnyPublisher<CustodialAccountBalanceState, Never> {
        balances
            .map { response -> CustodialAccountBalanceState in
                response[currencyType]
            }
            .eraseToAnyPublisher()
    }

    func fetchBalances() -> AnyPublisher<CustodialAccountBalanceStates, Never> {
        cachedValue
            .get(key: Key(), forceFetch: true)
            .replaceError(with: .absent)
            .eraseToAnyPublisher()
    }
}
