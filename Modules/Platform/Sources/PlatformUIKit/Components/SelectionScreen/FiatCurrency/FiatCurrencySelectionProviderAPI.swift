// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxSwift

public protocol FiatCurrencySelectionProviderAPI {
    var currencies: Observable<[FiatCurrency]> { get }
}

public final class DefaultFiatCurrencySelectionProvider: FiatCurrencySelectionProviderAPI {
    public let currencies: Observable<[FiatCurrency]>

    public init(availableCurrencies: [FiatCurrency] = FiatCurrency.supported) {
        currencies = .just(availableCurrencies)
    }
}
