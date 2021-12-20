// Copyright © Blockchain Luxembourg S.A. All rights reserved.

/// A pair of base-quote money values. Read about [Currency pairs](https://en.wikipedia.org/wiki/Currency_pair) for more information.
public struct MoneyValuePair: Equatable {

    // MARK: - Public Properties

    /// The base money value.
    public let base: MoneyValue

    /// The quote money value.
    public let quote: MoneyValue

    // MARK: - Setup

    /// Creates a money value pair.
    ///
    /// - Parameters:
    ///   - base:         A base money value.
    ///   - exchangeRate: An exchange rate, representing one major unit of `base`'s currency in another currency.
    public init(base: MoneyValue, exchangeRate: MoneyValue) {
        self.init(
            base: base,
            quote: base.convert(using: exchangeRate)
        )
    }

    /// Creates a money value pair.
    ///
    /// - Parameters:
    ///   - base:         A base crypto value.
    ///   - exchangeRate: An exchange rate, representing one major unit of `base`'s currency in another currency.
    public init(base: CryptoValue, exchangeRate: FiatValue) {
        self.init(
            base: base.moneyValue,
            quote: base.convertToFiatValue(exchangeRate: exchangeRate).moneyValue
        )
    }

    /// Creates a money value pair.
    ///
    /// - Parameters:
    ///   - fiatValue:      A fiat value.
    ///   - exchangeRate:   An exchange rate to convert `fiatValue` to a crypto value.
    ///   - cryptoCurrency: A crypto currency.
    ///   - usesFiatAsBase: Whether to use the fiat value or the crypto value as the base.
    public init(fiatValue: FiatValue, exchangeRate: FiatValue, cryptoCurrency: CryptoCurrency, usesFiatAsBase: Bool) {
        let cryptoValue = fiatValue.convertToCryptoValue(exchangeRate: exchangeRate, cryptoCurrency: cryptoCurrency)

        if usesFiatAsBase {
            self.init(base: fiatValue.moneyValue, quote: cryptoValue.moneyValue)
        } else {
            self.init(base: cryptoValue.moneyValue, quote: fiatValue.moneyValue)
        }
    }

    /// Creates a money value pair.
    ///
    /// - Parameters:
    ///   - base:  A base money value.
    ///   - quote: A quote money value.
    public init(base: MoneyValue, quote: MoneyValue) {
        self.base = base
        self.quote = quote
    }

    // MARK: - Arithmetics

    /// Calculates the sum of two money value pairs.
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the base currencies or the quote currencies do not match.
    public static func + (lhs: MoneyValuePair, rhs: MoneyValuePair) throws -> MoneyValuePair {
        let base = try lhs.base + rhs.base
        let quote = try lhs.quote + rhs.quote
        return MoneyValuePair(base: base, quote: quote)
    }

    /// Calculates the difference of two money value pairs.
    ///
    /// - Parameters:
    ///   - lhs: The value to subtract.
    ///   - rhs: The value to subtract from `lhs`.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the base currencies or the quote currencies do not match.
    public static func - (lhs: MoneyValuePair, rhs: MoneyValuePair) throws -> MoneyValuePair {
        let base = try lhs.base - rhs.base
        let quote = try lhs.quote - rhs.quote
        return MoneyValuePair(base: base, quote: quote)
    }

    /// Creates a zero valued money value pair.
    ///
    /// - Parameters:
    ///   - baseCurrency:  A base currency.
    ///   - quoteCurrency: A quote currency.
    public static func zero(baseCurrency: CurrencyType, quoteCurrency: CurrencyType) -> MoneyValuePair {
        MoneyValuePair(
            base: .zero(currency: baseCurrency),
            quote: .zero(currency: quoteCurrency)
        )
    }

    /// Returns the value before a percentage increase/decrease (e.g. for a value of 15, and a `percentChange` of 0.5 i.e. 50%, this returns 10).
    ///
    /// - Parameter percentageChange: A percentage of change.
    public func value(before percentageChange: Double) -> MoneyValuePair {
        MoneyValuePair(
            base: base.value(before: percentageChange),
            quote: quote.value(before: percentageChange)
        )
    }
}

extension MoneyValuePair: CustomDebugStringConvertible {

    public var debugDescription: String {
        """
        MoneyValuePair: \
        base \(base.toDisplayString(includeSymbol: true)), \
        quote \(quote.toDisplayString(includeSymbol: true))
        """
    }
}
