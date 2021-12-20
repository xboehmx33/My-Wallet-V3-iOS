// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import PlatformKit

final class FiatCurrencyService: FiatCurrencyServiceAPI {

    var displayCurrencyPublisher: AnyPublisher<FiatCurrency, Never> {
        .just(localeCurrency)
    }

    var tradingCurrencyPublisher: AnyPublisher<FiatCurrency, Never> {
        .just(localeCurrency)
    }

    private var localeCurrency: FiatCurrency {
        guard let code = Locale.current.currencyCode,
              let fiatCurrency = FiatCurrency(code: code)
        else {
            return .USD
        }
        return fiatCurrency
    }
}
