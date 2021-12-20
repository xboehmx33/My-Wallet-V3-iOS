// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

/// `MoneyValueBalancePairs` represents all the balances
/// for a given asset type. There are multiple `BalanceTypes`.
/// This allows for a total pairs that represents
/// the users balance across all `BalanceTypes`.
public struct MoneyValueBalancePairs: Equatable {

    /// The base currency type - either crypto or fiat
    public let baseCurrency: CurrencyType

    /// The quote currency type - either crypto or fiat
    public let quoteCurrency: CurrencyType

    public subscript(accountType: SingleAccountType) -> MoneyValuePair {
        moneyPairs[accountType] ?? .zero(baseCurrency: baseCurrency, quoteCurrency: quoteCurrency)
    }

    /// Returns true in case the balance is absent
    public let isAbsent: Bool

    // MARK: - Services

    private var moneyPairs: [SingleAccountType: MoneyValuePair] = [:]

    // MARK: - Setup

    /// Expects to be initialized with the wallet (non-custodial balance),
    /// trading (simplebuy account) balance, and savings (interest) account balance.
    /// All the base currencies must be equal to each other, as well as quotes
    /// - Parameters:
    ///   - wallet: Wallet balance
    ///   - trading: Trading balance
    ///   - savings: Savings balance
    public init(
        wallet: MoneyValuePair,
        trading: MoneyValuePair,
        savings: MoneyValuePair
    ) {
        guard wallet.base.currency == trading.base.currency,
              trading.base.currency == savings.base.currency
        else {
            fatalError("Mismatch in wallet/trading/savings base currency")
        }
        guard wallet.quote.currency == trading.quote.currency,
              trading.quote.currency == savings.quote.currency
        else {
            fatalError("Mismatch in wallet/trading/savings quote currency")
        }

        baseCurrency = trading.base.currency
        quoteCurrency = trading.quote.currency

        moneyPairs[.nonCustodial] = wallet
        moneyPairs[.custodial(.trading)] = trading
        moneyPairs[.custodial(.savings)] = savings
        isAbsent = false
    }

    public init(trading: MoneyValuePair) {
        baseCurrency = trading.base.currency
        quoteCurrency = trading.quote.currency
        moneyPairs[.custodial(.trading)] = trading
        isAbsent = false
    }

    /// Init' with an absent state -
    /// - Parameters:
    ///   - baseCurrency: The base currency type
    ///   - quoteCurrency: The quote currency type
    public init(baseCurrency: CurrencyType, quoteCurrency: CurrencyType) {
        self.baseCurrency = baseCurrency
        self.quoteCurrency = quoteCurrency
        isAbsent = true
    }
}

extension MoneyValueBalancePairs {

    /// The `MoneyValuePair` representing the total sum of bases and quotes
    /// across all `BalanceTypes`
    public var total: MoneyValuePair {
        .init(base: base, quote: quote)
    }

    /// The total value for the base currency
    public var base: MoneyValue {
        let total = moneyPairs.values.map(\.base.amount).reduce(0, +)
        return MoneyValue.create(minor: total, currency: baseCurrency)
    }

    /// The total value for the quote currency
    public var quote: MoneyValue {
        let total = moneyPairs.values.map(\.quote.amount).reduce(0, +)
        return MoneyValue.create(minor: total, currency: quoteCurrency)
    }

    /// `true` if `self` is zero.
    public var isZero: Bool {
        base.isZero || quote.isZero
    }
}

extension MoneyValueBalancePairs: CustomDebugStringConvertible {
    public var debugDescription: String {
        moneyPairs
            .map { "\($0.key.description): \($0.value.debugDescription)" }
            .joined(separator: " | ")
    }
}
