// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import ERC20Kit
import EthereumKit
import MoneyKit
import PlatformKit
import ToolKit

/// A repository in charge of getting ERC-20 token accounts associated with a given ethereum account address, providing value caching.
final class ERC20TokenAccountsRepository: ERC20TokenAccountsRepositoryAPI {

    // MARK: - Internal Types

    /// An ERC-20 token accounts key, used as cache index and network request parameter.
    struct ERC20TokenAccountsKey: Hashable {

        /// The ethereum account address.
        let address: String
    }

    // MARK: - Private Properties

    private let cachedValue: CachedValueNew<
        ERC20TokenAccountsKey,
        ERC20TokenAccounts,
        ERC20TokenAccountsError
    >

    // MARK: - Setup

    /// Creates an ERC-20 token accounts repository, with a preset cache that flushes on logout and has a 90 seconds refresh interval.
    ///
    /// - Parameters:
    ///   - client:                   An ERC-20 account client.
    ///   - enabledCurrenciesService: An enabled currencies service.
    convenience init(
        client: ERC20AccountClientAPI = resolve(),
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve()
    ) {
        let refreshControl = PeriodicCacheRefreshControl(refreshInterval: 60)
        let cache = InMemoryCache<ERC20TokenAccountsKey, ERC20TokenAccounts>(
            configuration: .onLoginLogoutTransaction(),
            refreshControl: refreshControl
        )
        .eraseToAnyCache()

        self.init(client: client, cache: cache, enabledCurrenciesService: enabledCurrenciesService)
    }

    /// Creates an ERC-20 token accounts repository.
    ///
    /// - Parameters:
    ///   - client:                   An ERC-20 account client.
    ///   - cache:                    A cache.
    ///   - enabledCurrenciesService: An enabled currencies service.
    init(
        client: ERC20AccountClientAPI = resolve(),
        cache: AnyCache<ERC20TokenAccountsKey, ERC20TokenAccounts>,
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve()
    ) {
        let mapper = ERC20TokenAccountsMapper(enabledCurrenciesService: enabledCurrenciesService)

        cachedValue = CachedValueNew(
            cache: cache,
            fetch: { key in
                client.tokens(for: key.address)
                    .map(mapper.toDomain)
                    .mapError(ERC20TokenAccountsError.network)
                    .retry(1)
                    .eraseToAnyPublisher()
            }
        )
    }

    // MARK: - Internal Methods

    func invalidateERC20TokenAccountsForAddress(
        _ address: EthereumAddress
    ) {
        cachedValue.invalidateCacheWithKey(
            ERC20TokenAccountsKey(address: address.publicKey)
        )
    }

    func tokens(
        for address: EthereumAddress,
        forceFetch: Bool
    ) -> AnyPublisher<ERC20TokenAccounts, ERC20TokenAccountsError> {
        cachedValue.get(
            key: ERC20TokenAccountsKey(address: address.publicKey),
            forceFetch: forceFetch
        )
    }

    func tokensStream(
        for address: EthereumAddress,
        skipStale: Bool
    ) -> StreamOf<ERC20TokenAccounts, ERC20TokenAccountsError> {
        cachedValue.stream(
            key: ERC20TokenAccountsKey(address: address.publicKey),
            skipStale: skipStale
        )
    }
}
