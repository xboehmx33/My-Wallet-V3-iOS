// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

/// An ERC-20 token account.
public struct ERC20TokenAccount: Equatable {

    /// The balance of the account.
    let balance: CryptoValue

    /// The symbol of the ERC-20 token (e.g. `AAVE`, `YFI`, etc.)
    let tokenSymbol: String

    /// Creates an ERC-20 token account.
    ///
    /// - Parameters:
    ///   - balance:     An ERC-20 balance.
    ///   - tokenSymbol: An ERC-20 token symbol.
    public init(balance: CryptoValue, tokenSymbol: String) {
        self.balance = balance
        self.tokenSymbol = tokenSymbol
    }
}

/// A dictionary of ERC-20 token accounts, indexed by ERC-20 crypto currencies.
public typealias ERC20TokenAccounts = [CryptoCurrency: ERC20TokenAccount]
