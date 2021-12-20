// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

public protocol InterestAccountServiceAPI: AnyObject, InterestAccountOverviewAPI {

    /// Fetches `InterestAccountBalanceDetails` for a given `CryptoCurrency`
    /// - Parameter currency: CryptoCurrency
    func fetchInterestAccountDetailsForCryptoCurrency(
        _ currency: CryptoCurrency
    ) -> Single<ValueCalculationState<InterestAccountBalanceDetails>>

    /// Fetches `InterestAccountLimits`, if the limits exist, for
    /// a given `CryptoCurrency`. Note that the repository fetches
    /// the limits using both the given `CryptoCurrency` and the users
    /// currently selected `FiatCurrency`.
    /// - Parameter currency: CryptoCurency
    func fetchInterestAccountLimitsForCryptoCurrency(
        _ currency: CryptoCurrency
    ) -> Single<InterestAccountLimits?>
}
