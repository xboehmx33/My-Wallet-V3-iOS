// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureTransactionDomain
import MoneyKit
import PlatformKit

struct CrossBorderLimitsResponse: Decodable {

    let currency: FiatCurrency
    let current: PeriodicLimits?
    let suggestedUpgrade: SuggestedLimitsUpgrade?
}

extension CrossBorderLimits {

    init(_ response: CrossBorderLimitsResponse) {
        self.init(
            currency: response.currency.currencyType,
            currentLimits: response.current,
            suggestedUpgrade: response.suggestedUpgrade
        )
    }
}
