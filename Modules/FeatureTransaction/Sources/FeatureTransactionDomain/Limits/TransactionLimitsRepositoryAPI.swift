// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError
import PlatformKit

/// Use this protocol to fetch limits data specific to an internal use case.
///
/// Implement this protocol in the Data Layer and use it only internally.
/// This IS NOT meant to be used by the `TransactionEngine`s to build a transaction. Use `TransactionLimitsServiceAPI` for that instead!
public protocol TransactionLimitsRepositoryAPI {

    func fetchTradeLimits(
        sourceCurrency: CurrencyType,
        destinationCurrency: CurrencyType,
        product: TransactionLimitsProduct
    ) -> AnyPublisher<TradeLimits, NabuNetworkError>

    func fetchCrossBorderLimits(
        source: LimitsAccount,
        destination: LimitsAccount,
        limitsCurrency: FiatCurrency
    ) -> AnyPublisher<CrossBorderLimits, NabuNetworkError>
}
