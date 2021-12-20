// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MoneyKit
import PlatformKit
import PlatformUIKit
import ToolKit

struct InterestAccountOverviewBalanceSummary: Equatable, Identifiable {

    var id: String {
        currency.code + cryptoBalance + fiatBalance
    }

    let currency: CurrencyType
    let cryptoBalance: String
    let fiatBalance: String

    var badgeImageViewModel: BadgeImageViewModel {
        let model: BadgeImageViewModel = .default(
            image: currency.logoResource,
            cornerRadius: .round,
            accessibilityIdSuffix: ""
        )
        model.marginOffsetRelay.accept(0)
        return model
    }
}
