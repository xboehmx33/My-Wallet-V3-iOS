// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit

public protocol FiatCurrencySettingsServiceAPI: SupportedFiatCurrenciesServiceAPI {

    /// Updates the display fiat currency associated with the wallet
    /// - Parameter displayCurrency: The new display fiat currency to use for displaying amounts to the user
    /// - Parameter context: The context in which the request has happened
    /// - Returns: A `AnyPublisher<Void, Error>`
    func update(displayCurrency: FiatCurrency, context: FlowContext) -> AnyPublisher<Void, CurrencyUpdateError>

    /// Updates the trading fiat currency associated with the wallet
    /// - Parameter tradingCurrency: The new trading currency to use as i/o fiat during trading
    /// - Parameter context: The context in which the request has happened
    /// - Returns: A `AnyPublisher<Void, Error>`
    func update(tradingCurrency: FiatCurrency, context: FlowContext) -> AnyPublisher<Void, CurrencyUpdateError>
}
