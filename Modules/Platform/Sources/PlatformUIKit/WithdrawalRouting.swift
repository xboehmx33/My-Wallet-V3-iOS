//
//  WithdrawalRouting.swift
//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.
//

import MoneyKit
import PlatformKit

public protocol WithdrawalRouting {

    func withdrawalBuilder(for currency: FiatCurrency) -> WithdrawBuildable
}
