// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import PlatformUIKit

final class AssetPriceCellInteractor {
    let priceViewInteractor: AssetPriceViewInteracting
    let currency: CryptoCurrency

    init(
        cryptoCurrency: CryptoCurrency,
        priceService: PriceServiceAPI,
        fiatCurrencyService: FiatCurrencyServiceAPI
    ) {
        currency = cryptoCurrency
        priceViewInteractor = AssetPriceViewDailyInteractor(
            cryptoCurrency: cryptoCurrency,
            priceService: priceService,
            fiatCurrencyService: fiatCurrencyService
        )
    }
}
