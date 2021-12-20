// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import DIKit
import PlatformKit
import RxSwift
import RxToolKit
import ToolKit

public protocol EthereumAccountDetailsServiceAPI {

    /// Invalidates the `EthereumAssetAccountDetails` cache.
    /// This is used after a transaction completes to ensure
    /// views show the latest balance.
    func invalidateEthereumAccountDetails()

    /// Streams the default account details.
    func accountDetails() -> Single<EthereumAssetAccountDetails>
}

final class EthereumAccountDetailsService: EthereumAccountDetailsServiceAPI {

    // MARK: - Properties

    private let accountRepository: EthereumWalletAccountRepositoryAPI
    private let client: BalanceClientAPI
    private let cache: CachedValue<EthereumAssetAccountDetails>

    // MARK: - Setup

    init(
        accountRepository: EthereumWalletAccountRepositoryAPI = resolve(),
        client: BalanceClientAPI = resolve(),
        scheduler: SchedulerType = CachedValueConfiguration.generateScheduler(identifier: "EthereumAccountDetailsService")
    ) {
        self.accountRepository = accountRepository
        self.client = client
        cache = CachedValue(
            configuration: .periodic(
                seconds: 30,
                scheduler: scheduler
            )
        )
        cache.setFetch { [accountRepository, client] in
            accountRepository.defaultAccount
                .eraseError()
                .flatMap { account in
                    client.balanceDetails(from: account.publicKey)
                        .map { details in
                            EthereumAssetAccountDetails(
                                account: account,
                                balance: details.cryptoValue,
                                nonce: details.nonce
                            )
                        }
                        .eraseError()
                }
                .asSingle()
        }
    }

    func accountDetails() -> Single<EthereumAssetAccountDetails> {
        cache.valueSingle
    }

    func invalidateEthereumAccountDetails() {
        cache
            .invalidate()
    }
}
