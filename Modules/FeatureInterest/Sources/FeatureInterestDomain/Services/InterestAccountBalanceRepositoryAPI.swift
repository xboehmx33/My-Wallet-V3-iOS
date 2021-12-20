// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import NetworkKit
import PlatformKit
import ToolKit

public enum InterestAccountBalanceRepositoryError: Error {
    case networkError(Error)
}

public protocol InterestAccountBalanceRepositoryAPI: AnyObject {

    /// Invalidates the cached balance for a given `FiatCurrency`
    /// This `FiatCurrency` should be the users displayCurrency.
    func invalidateAccountBalanceCacheWithKey(_ fiatCurrency: FiatCurrency)

    /// Fetches `InterestAccountBalances` for a given `FiatCurrency`.
    /// Use the subscript function on `InterestAccountBalances` to
    /// return a `InterestAccountBalanceDetails` for a given
    /// CryptoCurrency.
    /// - Parameter fiatCurrency: FiatCurrency
    func fetchInterestAccountsBalance(
        fiatCurrency: FiatCurrency
    ) -> AnyPublisher<InterestAccountBalances, InterestAccountBalanceRepositoryError>
}
