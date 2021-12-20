// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit

extension DependencyContainer {

    // MARK: - BitcoinKit Module

    public static var stellarKit = module {

        factory { HorizonProxy() as HorizonProxyAPI }

        factory { StellarAccountDetailsService() as StellarAccountDetailsServiceAPI }

        single { () -> StellarConfigurationAPI in
            StellarConfigurationService()
        }

        factory { () -> StellarWalletOptionsBridgeAPI in
            StellarWalletOptionsService()
        }

        single { StellarWalletAccountRepository() as StellarWalletAccountRepositoryAPI }

        factory(tag: CryptoCurrency.coin(.stellar)) { StellarAsset() as CryptoAsset }

        factory { () -> AnyActivityItemEventDetailsFetcher<StellarActivityItemEventDetails> in
            AnyActivityItemEventDetailsFetcher(api: StellarActivityItemEventDetailsFetcher())
        }

        single { AnyCryptoFeeService(service: CryptoFeeService<StellarTransactionFee>()) }

        factory { StellarTransactionDispatcher() }

        factory { LedgersServiceProvider() as LedgersServiceProviderAPI }

        factory { StellarHistoricalTransactionService() as StellarHistoricalTransactionServiceAPI }
    }
}
