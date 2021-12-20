// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Foundation

/// A money value.
public struct MoneyValue: Money, Hashable {

    // MARK: - Private Types

    /// A wrapped money implementing value.
    private enum Value: Hashable {

        case fiat(FiatValue)

        case crypto(CryptoValue)
    }

    // MARK: - Public properties

    public var currency: CurrencyType {
        switch _value {
        case .crypto(let cryptoValue):
            return cryptoValue.currencyType
        case .fiat(let fiatValue):
            return fiatValue.currencyType
        }
    }

    public var amount: BigInt {
        switch _value {
        case .crypto(let cryptoValue):
            return cryptoValue.amount
        case .fiat(let fiatValue):
            return fiatValue.amount
        }
    }

    /// Whether the money value is a crypto value.
    public var isCrypto: Bool {
        switch _value {
        case .crypto:
            return true
        case .fiat:
            return false
        }
    }

    /// Whether the money value is a fiat value.
    public var isFiat: Bool {
        switch _value {
        case .crypto:
            return false
        case .fiat:
            return true
        }
    }

    /// The fiat value, or `nil` if not a fiat value.
    public var fiatValue: FiatValue? {
        switch _value {
        case .crypto:
            return nil
        case .fiat(let fiatValue):
            return fiatValue
        }
    }

    /// The crypto value, or `nil` if not a crypto value.
    public var cryptoValue: CryptoValue? {
        switch _value {
        case .crypto(let cryptoValue):
            return cryptoValue
        case .fiat:
            return nil
        }
    }

    // MARK: - Private properties

    private let _value: Value

    // MARK: - Setup

    /// Creates a money value.
    ///
    /// - Parameter cryptoValue: A crypto value.
    public init(cryptoValue: CryptoValue) {
        _value = .crypto(cryptoValue)
    }

    /// Creates a money value.
    ///
    /// - Parameter fiatValue: A fiat value.
    public init(fiatValue: FiatValue) {
        _value = .fiat(fiatValue)
    }

    /// Creates a money value.
    ///
    /// - Parameters:
    ///   - amount:   An amount in minor units.
    ///   - currency: A currency.
    public init(amount: BigInt, currency: CurrencyType) {
        switch currency {
        case .crypto(let cryptoCurrency):
            _value = .crypto(CryptoValue(amount: amount, currency: cryptoCurrency))
        case .fiat(let fiatCurrency):
            _value = .fiat(FiatValue(amount: amount, currency: fiatCurrency))
        }
    }

    /// Creates a money value.
    ///
    /// - Parameters:
    ///   - amount:   An amount in major units.
    ///   - currency: A currency.
    private init(major amount: Decimal, currency: CurrencyType) {
        switch currency {
        case .crypto(let cryptoCurrency):
            _value = .crypto(CryptoValue.create(major: amount, currency: cryptoCurrency))
        case .fiat(let fiatCurrency):
            _value = .fiat(FiatValue.create(major: amount, currency: fiatCurrency))
        }
    }

    // MARK: - Public methods

    /// Creates a displayable string, representing the currency amount in major units, in the given locale, optionally including the currency symbol.
    ///
    /// - Parameters:
    ///   - includeSymbol: Whether the symbol should be included.
    ///   - locale:        A locale.
    public func toDisplayString(includeSymbol: Bool, locale: Locale) -> String {
        switch _value {
        case .crypto(let cryptoValue):
            return cryptoValue.toDisplayString(includeSymbol: includeSymbol, locale: locale)
        case .fiat(let fiatValue):
            return fiatValue.toDisplayString(includeSymbol: includeSymbol, locale: locale)
        }
    }

    /// Returns the value before a percentage increase/decrease (e.g. for a value of 15, and a `percentChange` of 0.5 i.e. 50%, this returns 10).
    ///
    /// - Parameter percentageChange: A percentage of change.
    public func value(before percentageChange: Double) -> MoneyValue {
        switch _value {
        case .crypto(let cryptoValue):
            return MoneyValue(cryptoValue: cryptoValue.value(before: percentageChange))
        case .fiat(let fiatValue):
            return MoneyValue(fiatValue: fiatValue.value(before: percentageChange))
        }
    }

    // MARK: - Public factory methods

    /// Creates a zero valued money value (e.g. `0 USD`, `0 BTC`, etc.).
    ///
    /// - Parameter currency: A crypto currency.
    public static func zero(currency: CryptoCurrency) -> MoneyValue {
        MoneyValue(cryptoValue: .zero(currency: currency))
    }

    /// Creates a zero valued money value (e.g. `0 USD`, `0 BTC`, etc.).
    ///
    /// - Parameter currency: A fiat currency.
    public static func zero(currency: FiatCurrency) -> MoneyValue {
        MoneyValue(fiatValue: .zero(currency: currency))
    }

    /// Creates a one (major unit) valued money value (e.g. `1 USD`, `1 BTC`, etc.).
    ///
    /// - Parameter currency: A crypto currency.
    public static func one(currency: CryptoCurrency) -> MoneyValue {
        MoneyValue(cryptoValue: .one(currency: currency))
    }

    /// Creates a one (major unit) valued money value (e.g. `1 USD`, `1 BTC`, etc.).
    ///
    /// - Parameter currency: A fiat currency.
    public static func one(currency: FiatCurrency) -> MoneyValue {
        MoneyValue(fiatValue: .one(currency: currency))
    }

    // MARK: - Public Methods

    /// Converts the current money value with currency `A` into another money value with currency `B`, using a given exchange rate from `A` to `B`.
    ///
    /// - Parameter exchangeRate: An exchange rate, representing one major unit of currency `A` in currency `B`.
    public func convert(using exchangeRate: MoneyValue) -> MoneyValue {
        guard currency != exchangeRate.currency else {
            // Converting to the same currency.
            return self
        }
        guard !isZero, !exchangeRate.isZero else {
            return .zero(currency: exchangeRate.currency)
        }
        let conversionAmount = displayMajorValue * exchangeRate.displayMajorValue
        return MoneyValue(major: conversionAmount, currency: exchangeRate.currency)
    }

    /// Converts the current money value with currency `A` into another money value with currency `B`, using a given exchange rate from `B` to `A`.
    ///
    /// - Parameters:
    ///   - exchangeRate: An exchange rate, representing one major unit of currency `B` in currency `A`.
    ///   - currencyType: The destination currency `B`.
    public func convert(usingInverse exchangeRate: MoneyValue, currencyType: CurrencyType) -> MoneyValue {
        guard !isZero, !exchangeRate.isZero else {
            return .zero(currency: currencyType)
        }
        let conversionAmount = displayMajorValue / exchangeRate.displayMajorValue
        return MoneyValue(major: conversionAmount, currency: currencyType)
    }

    /// Converts the current money value with currency `A` into another money value with currency `B`, using a given exchange rate pair from `A` to `B`.
    ///
    /// - Parameter exchangeRate: An exchange rate, representing a money value pair with the base in currency `A`, and the quote in currency `B`.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the current currency and the `exchangeRate`'s base currency do not match.
    public func convert(using exchangeRate: MoneyValuePair) throws -> MoneyValue {
        guard currency != exchangeRate.quote.currency else {
            // Converting to the same currency.
            return self
        }
        guard currency == exchangeRate.base.currency else {
            throw MoneyOperatingError.mismatchingCurrencies(currency, exchangeRate.base.currency)
        }
        return convert(using: exchangeRate.quote)
    }
}

extension MoneyValue: MoneyOperating {}

extension MoneyValue {

    public var shortDisplayString: String {
        let formattedMinimum: String
        if let fiatValue = fiatValue?.displayableRounding(decimalPlaces: 0, roundingMode: .bankers) {
            formattedMinimum = fiatValue.toDisplayString(includeSymbol: true, format: .shortened, locale: .current)
        } else {
            formattedMinimum = displayString
        }
        return formattedMinimum
    }

    /// Used for analytics purposes only, for other things use `displayString` instead.
    public var displayMajorValue: Decimal {
        amount.toDecimalMajor(
            baseDecimalPlaces: currencyType.precision,
            roundingDecimalPlaces: currencyType.precision
        )
    }
}

extension CryptoValue {

    /// Creates a money value from the current `CryptoValue`.
    public var moneyValue: MoneyValue {
        MoneyValue(cryptoValue: self)
    }
}

extension FiatValue {

    /// Creates a money value from the current `FiatValue`.
    public var moneyValue: MoneyValue {
        MoneyValue(fiatValue: self)
    }
}
