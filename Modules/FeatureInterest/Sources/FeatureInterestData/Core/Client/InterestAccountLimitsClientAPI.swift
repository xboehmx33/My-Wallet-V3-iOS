// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NabuNetworkError

protocol InterestAccountLimitsClientAPI: AnyObject {
    func fetchInterestAccountLimitsResponseForFiatCurrency(_ fiatCurrency: FiatCurrency)
        -> AnyPublisher<InterestAccountLimitsResponse, NabuNetworkError>
}
