// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Foundation

public protocol MoneyImplementing: Money {

    /// A currency type.
    associatedtype MoneyCurrency: Currency

    /// The currency.
    var currency: MoneyCurrency { get }

    /// Creates a money.
    ///
    /// - Parameters:
    ///   - amount:   An amount in minor units.
    ///   - currency: A currency.
    init(amount: BigInt, currency: MoneyCurrency)
}

extension MoneyImplementing {

    public var currencyType: CurrencyType {
        currency.currencyType
    }

    /// Creates a zero valued money (e.g. `0 USD`, `0 BTC`, etc.).
    ///
    /// - Parameter currency: A currency.
    public static func zero(currency: MoneyCurrency) -> Self {
        create(minor: 0, currency: currency)
    }

    /// Creates a one (major unit) valued money (e.g. `1 USD`, `1 BTC`, etc.).
    ///
    /// - Parameter currency: A currency.
    public static func one(currency: MoneyCurrency) -> Self {
        create(major: 1, currency: currency)
    }

    // MARK: - Major value

    /// Creates a money.
    ///
    /// - Parameters:
    ///   - value:    An amount in major units. Valid if it can be converted to a `Decimal` using the user's current locale.
    ///   - currency: A currency.
    ///
    /// - Returns: A money, or `nil` if `value` is invalid.
    public static func create(majorDisplay value: String, currency: MoneyCurrency) -> Self? {
        create(major: value, currency: currency, locale: Locale.current)
    }

    /// Creates a money.
    ///
    /// - Parameters:
    ///   - value:    An amount in major units. Valid if it can be converted to a `Decimal` using the `POSIX` locale.
    ///   - currency: A currency.
    ///
    /// - Returns: A money, or `nil` if `value` is invalid.
    public static func create(major value: String, currency: MoneyCurrency) -> Self? {
        create(major: value, currency: currency, locale: Locale.Posix)
    }

    /// Creates a money.
    ///
    /// - Parameters:
    ///   - value:    An amount in major units.
    ///   - currency: A currency.
    public static func create(major value: Decimal, currency: MoneyCurrency) -> Self {
        let minorDecimal = value * pow(10, currency.precision)
        return create(minor: minorDecimal, currency: currency)
    }

    // MARK: - Minor value

    /// Creates a money.
    ///
    /// - Parameters:
    ///   - value:    An amount in minor units. Valid if it can be converted to a `BigInt`.
    ///   - currency: A currency.
    ///
    /// - Returns: A money, or `nil` if `value` is invalid.
    public static func create(minor value: String, currency: MoneyCurrency) -> Self? {
        guard let amount = BigInt(value) else {
            return nil
        }
        return Self(amount: amount, currency: currency)
    }

    /// Creates a money.
    ///
    /// - Parameters:
    ///   - value:    An amount in minor units. Any fractional digits will be trimmed.
    ///   - currency: A currency.
    public static func create(minor value: Decimal, currency: MoneyCurrency) -> Self {
        let amount = BigInt(stringLiteral: "\(value.roundTo(places: 0))")
        return Self(amount: amount, currency: currency)
    }

    /// Creates a money.
    ///
    /// - Parameters:
    ///   - value:    An amount in minor units.
    ///   - currency: A currency.
    public static func create(minor value: Int, currency: MoneyCurrency) -> Self {
        Self(amount: BigInt(value), currency: currency)
    }

    /// Creates a money.
    ///
    /// - Parameters:
    ///   - value:    An amount in minor units.
    ///   - currency: A currency.
    public static func create(minor value: BigInt, currency: MoneyCurrency) -> Self {
        Self(amount: value, currency: currency)
    }

    // MARK: - Private methods

    /// Creates a money.
    ///
    /// - Parameters:
    ///   - value:    An amount in major units. Valid if it can be converted to a `Decimal` using `locale`.
    ///   - currency: A currency.
    ///   - locale:   A locale.
    ///
    /// - Returns: A money, or `nil` if `value` is invalid.
    private static func create(major value: String, currency: MoneyCurrency, locale: Locale) -> Self? {
        guard let majorDecimal = Decimal(string: value, locale: locale), !majorDecimal.isNaN else {
            return nil
        }
        return create(major: majorDecimal, currency: currency)
    }
}
