// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import ERC20DataKit
import MoneyKit
import PlatformKit

extension ERC20TokenAccountsResponse {

    /// Creates a stubbed ERC-20 tokens endpoint response.
    ///
    /// - Parameter cryptoCurrency: An ERC-20 crypto currency.
    static func stubbed(cryptoCurrency: CryptoCurrency) -> ERC20TokenAccountsResponse {
        .init(
            tokenAccounts: [
                .stubbed(cryptoCurrency: cryptoCurrency)
            ]
        )
    }
}
