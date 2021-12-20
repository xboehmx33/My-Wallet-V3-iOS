// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import RxSwift
import ToolKit

protocol InterestAccountDetailsClientAPI {
    func balance(with fiatCurrency: FiatCurrency) -> Single<SavingsAccountBalanceResponse?>
}

final class InterestAccountDetailsClient: InterestAccountDetailsClientAPI {

    func balance(with fiatCurrency: FiatCurrency) -> Single<SavingsAccountBalanceResponse?> {
        unimplemented()
    }
}
