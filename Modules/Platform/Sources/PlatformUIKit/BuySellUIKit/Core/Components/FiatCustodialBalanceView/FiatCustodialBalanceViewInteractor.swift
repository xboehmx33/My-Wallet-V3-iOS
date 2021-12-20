// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxRelay
import RxSwift
import ToolKit

public final class FiatCustodialBalanceViewInteractor {

    let balanceViewInteractor: FiatBalanceViewInteractor
    let currencyType: CurrencyType

    public var fiatCurrency: Observable<FiatCurrency> {
        guard case .fiat(let currency) = currencyType else {
            fatalError("The base currency of `FiatCustodialBalanceViewInteractor` must be a fiat currency type")
        }
        return .just(currency)
    }

    init(account: SingleAccount) {
        currencyType = account.currencyType
        balanceViewInteractor = FiatBalanceViewInteractor(account: account)
    }

    public init(balance: MoneyValue) {
        currencyType = balance.currency
        balanceViewInteractor = FiatBalanceViewInteractor(balance: balance)
    }
}

extension FiatCustodialBalanceViewInteractor: Equatable {
    public static func == (lhs: FiatCustodialBalanceViewInteractor, rhs: FiatCustodialBalanceViewInteractor) -> Bool {
        lhs.currencyType == rhs.currencyType
    }
}
