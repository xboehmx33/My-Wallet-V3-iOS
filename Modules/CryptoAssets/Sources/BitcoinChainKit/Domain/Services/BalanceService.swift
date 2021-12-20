// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import PlatformKit
import ToolKit

public protocol BalanceServiceAPI {

    /// Invalidates the balance cache for a given `XPub`.
    /// After a transaction completes we want to invalidate the balance
    /// cache to ensure all views show the latest balance.
    func invalidateBalanceForWallet(_ wallet: XPub)

    func balance(for wallet: XPub) -> AnyPublisher<CryptoValue, Error>

    func balances(for wallets: [XPub]) -> AnyPublisher<CryptoValue, Error>
}

final class BalanceService: BalanceServiceAPI {

    private let client: APIClientAPI
    private let coin: BitcoinChainCoin
    private let cachedValue: CachedValueNew<
        Set<XPub>,
        CryptoValue,
        Error
    >

    convenience init(coin: BitcoinChainCoin) {
        self.init(client: resolve(tag: coin), coin: coin)
    }

    init(client: APIClientAPI, coin: BitcoinChainCoin) {
        self.client = client
        self.coin = coin
        let cache: AnyCache<Set<XPub>, CryptoValue> = InMemoryCache(
            configuration: .onLoginLogout(),
            refreshControl: PeriodicCacheRefreshControl(refreshInterval: 60)
        ).eraseToAnyCache()
        cachedValue = CachedValueNew(
            cache: cache,
            fetch: { key in
                client.balances(for: key.map(\.self))
                    .map { response in
                        BitcoinChainBalances(response: response, coin: coin)
                    }
                    .map(\.total)
                    .eraseError()
            }
        )
    }

    // MARK: - BalanceServiceAPI

    func invalidateBalanceForWallet(_ wallet: XPub) {
        cachedValue.invalidateCacheWithKey([wallet])
    }

    func balance(for wallet: XPub) -> AnyPublisher<CryptoValue, Error> {
        balances(for: [wallet])
    }

    func balances(for wallets: [XPub]) -> AnyPublisher<CryptoValue, Error> {
        cachedValue.get(key: Set(wallets))
    }
}

private struct BitcoinChainBalances {

    let total: CryptoValue

    init(response: BitcoinChainBalanceResponse, coin: BitcoinChainCoin) {
        total = (try? response.values
            .map { item in .create(minor: item.finalBalance, currency: coin.cryptoCurrency) }
            .reduce(.zero(currency: coin.cryptoCurrency), +)
        ) ?? .zero(currency: coin.cryptoCurrency)
    }
}
