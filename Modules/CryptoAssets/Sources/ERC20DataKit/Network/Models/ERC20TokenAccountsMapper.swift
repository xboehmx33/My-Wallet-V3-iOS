// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ERC20Kit
import MoneyKit
import PlatformKit

/// A mapper for ERC-20 token accounts data model to domain model.
final class ERC20TokenAccountsMapper {

    // MARK: - Private Properties

    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI

    // MARK: - Setup

    /// Creates an ERC-20 token accounts mapper.
    ///
    /// - Parameter enabledCurrenciesService: An enabled currencies service.
    init(enabledCurrenciesService: EnabledCurrenciesServiceAPI) {
        self.enabledCurrenciesService = enabledCurrenciesService
    }

    // MARK: - Internal Methods

    /// Maps the given ERC-20 token accounts from the data model to the domain model.
    ///
    /// - Parameter tokenAccountsResponse: An ERC-20 token accounts as a data model.
    ///
    /// - Returns: An ERC-20 token accounts as a domain model.
    func toDomain(tokenAccountsResponse: ERC20TokenAccountsResponse) -> ERC20TokenAccounts {
        tokenAccountsResponse.tokenAccounts
            .reduce(into: [:]) { accounts, account in
                if let tokenCurrency = CryptoCurrency(
                    erc20Address: account.tokenHash,
                    enabledCurrenciesService: enabledCurrenciesService
                ), let balance = CryptoValue.create(
                    minor: account.balance,
                    currency: tokenCurrency
                ) {
                    accounts[tokenCurrency] = ERC20TokenAccount(
                        balance: balance,
                        tokenSymbol: account.tokenSymbol
                    )
                }
            }
    }
}
