// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import PlatformKit

final class NoOpFiatCurrencyPublisher: FiatCurrencyServiceAPI {

    var displayCurrencyPublisher: AnyPublisher<FiatCurrency, Never> {
        .just(.USD)
    }

    var tradingCurrencyPublisher: AnyPublisher<FiatCurrency, Never> {
        .just(.USD)
    }
}
