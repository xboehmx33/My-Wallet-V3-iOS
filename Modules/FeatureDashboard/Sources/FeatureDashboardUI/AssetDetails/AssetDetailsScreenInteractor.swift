// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxSwift

final class AssetDetailsScreenInteractor {

    // MARK: - Public Properties

    var nonCustodialAccount: Single<BlockchainAccount> {
        blockchainAccountFetcher
            .account(for: currency.currencyType, accountType: .nonCustodial)
    }

    var tradingAccount: Single<BlockchainAccount> {
        blockchainAccountFetcher
            .account(for: currency.currencyType, accountType: .custodial(.trading))
    }

    var interestAccountIfFunded: Single<BlockchainAccount?> {
        blockchainAccountFetcher
            .account(for: currency.currencyType, accountType: .custodial(.savings))
            .flatMap { account -> Single<BlockchainAccount?> in
                account.isFunded.map { isFunded -> BlockchainAccount? in
                    isFunded ? account : nil
                }
            }
    }

    var rate: Single<Double> {
        savingsAccountService
            .rate(for: currency)
    }

    let historicalFiatPriceService: HistoricalFiatPriceServiceAPI
    let fiatCurrencyService: FiatCurrencyServiceAPI

    // MARK: - Private Properties

    private let blockchainAccountFetcher: BlockchainAccountFetching
    private let currency: CryptoCurrency
    private let savingsAccountService: InterestAccountOverviewAPI
    private let recoveryPhraseStatus: RecoveryPhraseStatusProviding
    private let coincore: CoincoreAPI

    // MARK: - Setup

    init(
        currency: CryptoCurrency,
        coincore: CoincoreAPI = resolve(),
        savingsAccountService: InterestAccountOverviewAPI = resolve(),
        blockchainAccountFetcher: BlockchainAccountFetching = resolve(),
        fiatCurrencyService: FiatCurrencyServiceAPI = resolve(),
        pairExchangeService: PairExchangeServiceAPI
    ) {
        self.coincore = coincore
        self.blockchainAccountFetcher = blockchainAccountFetcher
        self.currency = currency
        self.savingsAccountService = savingsAccountService
        historicalFiatPriceService = HistoricalFiatPriceService(
            cryptoCurrency: currency,
            pairExchangeService: pairExchangeService,
            fiatCurrencyService: fiatCurrencyService
        )
        recoveryPhraseStatus = resolve()
        self.fiatCurrencyService = fiatCurrencyService
    }

    func refresh() {
        recoveryPhraseStatus.fetchTriggerRelay.accept(())
    }
}
