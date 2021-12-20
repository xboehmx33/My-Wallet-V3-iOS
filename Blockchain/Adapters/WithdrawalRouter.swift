//
//  WithdrawalRouter.swift
//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.
//

import MoneyKit
import PlatformKit
import PlatformUIKit

class WithdrawalRouter: WithdrawalRouting {

    func withdrawalBuilder(for currency: FiatCurrency) -> WithdrawBuildable {
        WithdrawBuilder(currency: currency)
    }
}
