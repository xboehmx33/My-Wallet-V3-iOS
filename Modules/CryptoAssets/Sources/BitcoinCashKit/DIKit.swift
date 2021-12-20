// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit

extension DependencyContainer {

    // MARK: - BitcoinCashKit Module

    public static var bitcoinCashKit = module {

        single { APIClient() as APIClientAPI }

        factory { BitcoinCashWalletAccountRepository() }

        factory(tag: CryptoCurrency.coin(.bitcoinCash)) { BitcoinCashAsset() as CryptoAsset }

        single { BitcoinCashHistoricalTransactionService() as BitcoinCashHistoricalTransactionServiceAPI }

        factory { () -> AnyActivityItemEventDetailsFetcher<BitcoinCashActivityItemEventDetails> in
            AnyActivityItemEventDetailsFetcher(api: BitcoinCashActivityItemEventDetailsFetcher())
        }
    }
}
