// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit

extension DependencyContainer {

    // MARK: - BitcoinKit Module

    public static var bitcoinKit = module {

        single { APIClient() as APIClientAPI }

        factory { BitcoinWalletAccountRepository() }

        factory(tag: CryptoCurrency.coin(.bitcoin)) { BitcoinAsset() as CryptoAsset }

        single { BitcoinHistoricalTransactionService() as BitcoinHistoricalTransactionServiceAPI }

        factory { () -> AnyActivityItemEventDetailsFetcher<BitcoinActivityItemEventDetails> in
            AnyActivityItemEventDetailsFetcher(api: BitcoinActivityItemEventDetailsFetcher())
        }
    }
}
