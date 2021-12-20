// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureTransactionDomain
import MoneyKit
import NabuNetworkError
import PlatformKit

protocol TransactionLimitsClientAPI {

    func fetchTradeLimits(
        currency: CurrencyType,
        networkFee: CurrencyType,
        product: TransactionLimitsProduct
    ) -> AnyPublisher<TradeLimitsResponse, NabuNetworkError>

    func fetchCrossBorderLimits(
        source: LimitsAccount,
        destination: LimitsAccount,
        limitsCurrency: CurrencyType
    ) -> AnyPublisher<CrossBorderLimitsResponse, NabuNetworkError>
}
