// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

public struct Portfolio: Codable {

    // MARK: - Types

    struct Account: Codable {
        let currency: CryptoCurrency
        let balance: String
        var cryptoValue: CryptoValue {
            CryptoValue.create(minor: balance, currency: currency) ?? .zero(currency: currency)
        }
    }

    public struct BalanceChange: Codable {
        let balance: Decimal
        public let changePercentage: Double
        let change: Decimal

        static let zero: BalanceChange = .init(
            balance: 0.0,
            changePercentage: 0.0,
            change: 0.0
        )
    }

    // MARK: - Public Properties

    public let balanceChange: BalanceChange
    let fiatCurrency: FiatCurrency
    public var balanceFiatValue: FiatValue {
        FiatValue.create(
            major: balanceChange.balance,
            currency: fiatCurrency
        )
    }

    public var changeFiatValue: FiatValue {
        FiatValue.create(
            major: balanceChange.change,
            currency: fiatCurrency
        )
    }

    subscript(currency: CryptoCurrency) -> Account {
        accounts[currency]!
    }

    // MARK: - Private Properties

    private var accounts: [CryptoCurrency: Account] = [:]

    // MARK: - Init

    init(
        accounts: [CryptoCurrency: Portfolio.Account],
        balanceChange: BalanceChange,
        fiatCurrency: FiatCurrency
    ) {
        self.accounts = accounts
        self.balanceChange = balanceChange
        self.fiatCurrency = fiatCurrency
    }
}
