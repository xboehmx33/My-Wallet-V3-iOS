// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxRelay
import RxSwift

public final class PricesScreenInteractor {

    // MARK: - Properties

    var enabledCryptoCurrencies: Observable<[CryptoCurrency]> {
        showSupportedPairsOnly
            ? supportedPairsInteractorService.fetchSupportedCryptoCurrenciesForTrading()
            : .just(enabledCurrenciesService.allEnabledCryptoCurrencies)
    }

    // MARK: - Private Properties

    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI
    private let fiatCurrencyService: FiatCurrencyServiceAPI
    private let priceService: PriceServiceAPI
    private let supportedPairsInteractorService: SupportedPairsInteractorServiceAPI
    private let showSupportedPairsOnly: Bool

    // MARK: - Init

    public init(
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve(),
        fiatCurrencyService: FiatCurrencyServiceAPI = resolve(),
        priceService: PriceServiceAPI = resolve(),
        supportedPairsInteractorService: SupportedPairsInteractorServiceAPI = resolve(),
        showSupportedPairsOnly: Bool
    ) {
        self.enabledCurrenciesService = enabledCurrenciesService
        self.fiatCurrencyService = fiatCurrencyService
        self.priceService = priceService
        self.supportedPairsInteractorService = supportedPairsInteractorService
        self.showSupportedPairsOnly = showSupportedPairsOnly
    }

    // MARK: - Methods

    func assetPriceViewInteractor(
        for currency: CryptoCurrency
    ) -> AssetPriceViewInteracting {
        AssetPriceViewDailyInteractor(
            cryptoCurrency: currency,
            priceService: priceService,
            fiatCurrencyService: fiatCurrencyService
        )
    }

    func refresh() {}
}
