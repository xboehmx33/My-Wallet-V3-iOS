// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

final class PortfolioCellInteractor {

    let balanceFiatValue: FiatValue
    let changeFiatValue: FiatValue
    let delta: String
    let isPositive: Bool

    init(portfolio: Portfolio) {
        let balanceChange = portfolio.balanceChange
        isPositive = balanceChange.changePercentage >= .zero
        balanceFiatValue = portfolio.balanceFiatValue
        changeFiatValue = portfolio.changeFiatValue
        let percentage = balanceChange.changePercentage * 100
        let percentageString = percentage.string(with: 2)
        delta = "(\(percentageString)%)"
    }
}
