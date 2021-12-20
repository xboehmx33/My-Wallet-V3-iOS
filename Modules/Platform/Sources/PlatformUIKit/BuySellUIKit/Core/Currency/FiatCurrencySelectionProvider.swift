// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxSwift

public final class FiatCurrencySelectionProvider: FiatCurrencySelectionProviderAPI {

    public var currencies: Observable<[FiatCurrency]> {
        supportedCurrencies
            .supportedFiatCurrencies
            .map { Array($0) }
            .asObservable()
    }

    private let supportedCurrencies: SupportedFiatCurrenciesServiceAPI

    public init(supportedCurrencies: SupportedFiatCurrenciesServiceAPI = resolve()) {
        self.supportedCurrencies = supportedCurrencies
    }
}
