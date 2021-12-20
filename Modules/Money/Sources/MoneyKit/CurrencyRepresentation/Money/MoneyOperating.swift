// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Foundation

/// A money operating error.
public enum MoneyOperatingError: Error {

    /// The currencies of two money do not match.
    case mismatchingCurrencies(Currency, Currency)

    /// Division with a zero divisior.
    case divideByZero
}

public protocol MoneyOperating: MoneyImplementing {}

extension MoneyOperating {

    // MARK: - Public Methods

    /// Returns the greater of two money.
    ///
    /// - Parameters:
    ///   - x: A value to compare.
    ///   - y: Another value to compare.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func max(_ x: Self?, _ y: Self?) throws -> Self? {
        guard let x = x, let y = y else {
            return x ?? y
        }
        return try x > y ? x : y
    }

    /// Returns the greater of two money.
    ///
    /// - Parameters:
    ///   - x: A value to compare.
    ///   - y: Another value to compare.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func max(_ x: Self, _ y: Self) throws -> Self {
        try x > y ? x : y
    }

    /// Returns the lesser of two money.
    ///
    /// - Parameters:
    ///   - x: A value to compare.
    ///   - y: Another value to compare.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func min(_ x: Self?, _ y: Self?) throws -> Self? {
        guard let x = x, let y = y else {
            return x ?? y
        }
        return try x < y ? x : y
    }

    /// Returns the lesser of two money.
    ///
    /// - Parameters:
    ///   - x: A value to compare.
    ///   - y: Another value to compare.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func min(_ x: Self, _ y: Self) throws -> Self {
        try x < y ? x : y
    }

    /// Returns a `Boolean` value indicating whether the value of the first argument is greater than that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func > (lhs: Self, rhs: Self) throws -> Bool {
        try ensureComparable(lhs, rhs)
        return lhs.amount > rhs.amount
    }

    /// Returns a `Boolean` value indicating whether the value of the first argument is greater than or equal to that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func >= (lhs: Self, rhs: Self) throws -> Bool {
        try ensureComparable(lhs, rhs)
        return lhs.amount >= rhs.amount
    }

    /// Returns a `Boolean` value indicating whether the value of the first argument is less than that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func < (lhs: Self, rhs: Self) throws -> Bool {
        try ensureComparable(lhs, rhs)
        return lhs.amount < rhs.amount
    }

    /// Returns a `Boolean` value indicating whether the value of the first argument is less than or equal to that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func <= (lhs: Self, rhs: Self) throws -> Bool {
        try ensureComparable(lhs, rhs)
        return lhs.amount <= rhs.amount
    }

    /// Calculates the sum of two money.
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func + (lhs: Self, rhs: Self) throws -> Self {
        try ensureComparable(lhs, rhs)
        return Self(amount: lhs.amount + rhs.amount, currency: lhs.currency)
    }

    /// Calculates the sum of two money and stores the result in the left-hand side variable.
    ///
    /// - Parameters:
    ///   - lhs: The first value to add.
    ///   - rhs: The second value to add.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func += (lhs: inout Self, rhs: Self) throws {
        lhs = try lhs + rhs
    }

    /// Calculates the difference of two money.
    ///
    /// - Parameters:
    ///   - lhs: The value to subtract.
    ///   - rhs: The value to subtract from `lhs`.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func - (lhs: Self, rhs: Self) throws -> Self {
        try ensureComparable(lhs, rhs)
        return Self(amount: lhs.amount - rhs.amount, currency: lhs.currency)
    }

    /// Calculates the difference of two money, and stores the result in the left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: The value to subtract.
    ///   - rhs: The value to subtract from `lhs`.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func -= (lhs: inout Self, rhs: Self) throws {
        lhs = try lhs - rhs
    }

    /// Calculates the product of two money.
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func * (lhs: Self, rhs: Self) throws -> Self {
        try ensureComparable(lhs, rhs)
        let productAmount = (lhs.amount * rhs.amount)
            .quotientAndRemainder(dividingBy: BigInt(10).power(lhs.precision))
            .quotient
        return Self(amount: productAmount, currency: lhs.currency)
    }

    /// Calculates the product of two money, and stores the result in the left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: The first value to multiply.
    ///   - rhs: The second value to multiply.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    public static func *= (lhs: inout Self, rhs: Self) throws {
        lhs = try lhs * rhs
    }

    /// Returns the quotient of dividing two money.
    ///
    /// - Parameters:
    ///   - lhs: The value to divide.
    ///   - rhs: The value to divide `lhs` by.
    ///
    /// - Throws:
    ///   A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    ///   A `MoneyOperatingError.divideByZero` if the `rhs` amount is zero.
    public static func / (lhs: Self, rhs: Self) throws -> Self {
        try ensureComparable(lhs, rhs)
        guard !rhs.isZero else {
            throw MoneyOperatingError.divideByZero
        }

        let decimalPower = BigInt(10).power(lhs.precision)
        let (quotient, remainder) = lhs.amount.quotientAndRemainder(dividingBy: rhs.amount)
        let quotientResult = quotient * decimalPower
        let remainderDivisor = rhs.amount / decimalPower
        guard remainder != 0, remainderDivisor != 0 else {
            return Self(amount: quotientResult, currency: lhs.currency)
        }

        let remainderResult = remainder / remainderDivisor
        return Self(amount: quotientResult + remainderResult, currency: lhs.currency)
    }

    /// Returns the quotient of dividing two money, and stores the result in the left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: The value to divide.
    ///   - rhs: The value to divide `lhs` by.
    ///
    /// - Throws:
    ///   A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    ///   A `MoneyOperatingError.divideByZero` if the `rhs` amount is zero.
    public static func /= (lhs: inout Self, rhs: Self) throws {
        lhs = try lhs / rhs
    }

    /// Returns the value before a percentage increase/decrease (e.g. for a value of 15, and a `percentChange` of 0.5 i.e. 50%, this returns 10).
    ///
    /// - Parameter percentageChange: A percentage of change.
    public func value(before percentageChange: Double) -> Self {
        let percentageChange = percentageChange + 1
        guard !percentageChange.isNaN, !percentageChange.isZero, percentageChange.isNormal else {
            return Self.zero(currency: currency)
        }
        let majorAmount = displayMajorValue / Decimal(percentageChange)
        return Self.create(major: majorAmount, currency: currency)
    }

    /// Returns the percentage of the current money in another, rounded to 4 decimal places.
    ///
    /// - Parameter other: The value to calculate the percentage in.
    public func percentage(in other: Self) throws -> Decimal {
        try Self.percentage(of: self, in: other)
    }

    /// Rounds the current value to the current currency's `displayPrecision`.
    ///
    /// - Warning: Rounding a money implies a **precision loss** for the underlying amount. This should only be used for displaying purposes.
    ///
    /// - Parameter roundingMode:  A rounding mode.
    public func displayableRounding(roundingMode: Decimal.RoundingMode) -> Self {
        displayableRounding(decimalPlaces: currency.displayPrecision, roundingMode: roundingMode)
    }

    /// Rounds the current value.
    ///
    /// - Warning: Rounding a money implies a **precision loss** for the underlying amount. This should only be used for displaying purposes.
    ///
    /// - Parameters:
    ///   - decimalPlaces: A number of decimal places.
    ///   - roundingMode:  A rounding mode.
    public func displayableRounding(decimalPlaces: Int, roundingMode: Decimal.RoundingMode) -> Self {
        Self.create(
            major: amount.toDecimalMajor(
                baseDecimalPlaces: currency.precision,
                roundingDecimalPlaces: decimalPlaces,
                roundingMode: roundingMode
            ),
            currency: currency
        )
    }

    // MARK: - Private Methods

    /// Returns the precentage of one money in another, rounded to 4 decimal places.
    ///
    /// - Parameters:
    ///   - x: The value to calculate the percentage of.
    ///   - y: The value to calculate the percentage in.
    private static func percentage(of x: Self, in y: Self) throws -> Decimal {
        try ensureComparable(x, y)
        return x.amount.decimalDivision(divisor: y.amount).roundTo(places: 4)
    }

    /// Checks that two money have matching currencies.
    ///
    /// - Parameters:
    ///   - x: A value.
    ///   - y: Another value.
    ///
    /// - Throws: A `MoneyOperatingError.mismatchingCurrencies` if the currencies do not match.
    private static func ensureComparable(_ x: Self, _ y: Self) throws {
        guard x.currencyType == y.currencyType else {
            throw MoneyOperatingError.mismatchingCurrencies(x.currency, y.currency)
        }
    }
}
