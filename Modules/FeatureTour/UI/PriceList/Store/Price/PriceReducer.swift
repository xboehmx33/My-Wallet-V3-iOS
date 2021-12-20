// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import ComposableNavigation
import MoneyKit
import PlatformKit

let priceReducer = Reducer<Price, PriceAction, PriceEnvironment> { state, action, environment in
    switch action {
    case .currencyDidLoad:
        return Publishers.Zip(
            environment
                .priceRepository
                .prices(of: [state.currency], in: FiatCurrency.USD, at: .now),
            environment
                .priceRepository
                .priceSeries(of: state.currency, in: FiatCurrency.USD, within: .day(.oneHour))
        )
        .receive(on: environment.mainQueue)
        .catchToEffect()
        .map { result in
            guard case .success((let pricesValue, let seriesValue)) = result,
                  let priceQuote = pricesValue.first?.value
            else {
                return .none
            }
            return .priceValuesDidLoad(price: priceQuote.moneyValue.displayString, delta: seriesValue.deltaPercentage)
        }
    case .priceValuesDidLoad(let price, let delta):
        state.value = .loaded(next: price)
        state.deltaPercentage = .loaded(next: delta)
        return .none
    case .none:
        return .none
    }
}
