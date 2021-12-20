// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit

public struct FundData: Equatable {
    /// The lesser between available amount and maximum limit.
    public let topLimit: FiatValue
    public let balance: FiatValue

    public var label: String {
        LocalizationConstants.Account.fiatAccount(topLimit.currency.name)
    }

    init(balance: CustodialAccountBalance, max: FiatValue) {
        let fiatBalance = balance.available.fiatValue!
        let useTotalBalance = (try? fiatBalance < max) ?? false
        if useTotalBalance {
            topLimit = fiatBalance
        } else {
            topLimit = max
        }
        self.balance = fiatBalance
    }
}
