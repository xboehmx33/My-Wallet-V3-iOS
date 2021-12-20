// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxRelay
import RxSwift

final class HistoricalBalanceCellInteractor {

    // MARK: - Properties

    let sparklineInteractor: SparklineInteracting
    let priceInteractor: AssetPriceViewInteracting
    let balanceInteractor: AssetBalanceViewInteracting
    let historicalFiatPriceService: HistoricalFiatPriceServiceAPI
    let cryptoCurrency: CryptoCurrency

    // MARK: - Setup

    init(
        cryptoAsset: CryptoAsset,
        historicalFiatPriceService: HistoricalFiatPriceServiceAPI,
        fiatCurrencyService: FiatCurrencyServiceAPI
    ) {
        cryptoCurrency = cryptoAsset.asset
        self.historicalFiatPriceService = historicalFiatPriceService
        sparklineInteractor = SparklineInteractor(
            priceService: historicalFiatPriceService,
            cryptoCurrency: cryptoCurrency
        )
        priceInteractor = AssetPriceViewHistoricalInteractor(
            historicalPriceProvider: historicalFiatPriceService
        )
        balanceInteractor = AccountAssetBalanceViewInteractor(
            cryptoAsset: cryptoAsset,
            fiatCurrencyService: fiatCurrencyService
        )
    }

    func refresh() {
        historicalFiatPriceService.fetchTriggerRelay.accept(.day(.oneHour))
        balanceInteractor.refresh()
    }
}
