// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt

/// A crypto money value.
public struct CryptoValue: CryptoMoney, Hashable {

    public let amount: BigInt

    public let currency: CryptoCurrency

    /// Creates a crypto value.
    ///
    /// - Parameters:
    ///   - amount:   An amount in minor units.
    ///   - currency: A crypto currency.
    public init(amount: BigInt, currency: CryptoCurrency) {
        self.amount = amount
        self.currency = currency
    }
}

extension CryptoValue: MoneyOperating {}

extension CryptoValue {

    // MARK: - Conversion

    /// Converts the current crypto value into a fiat value, using a given exchange rate from the fiat curency to the crypto currency.
    ///
    /// - Parameter exchangeRate: An exchange rate, representing one major unit of the fiat currency in the crypto currency.
    public func convertToFiatValue(exchangeRate: FiatValue) -> FiatValue {
        let conversionAmount = displayMajorValue * exchangeRate.displayMajorValue
        return FiatValue.create(major: conversionAmount, currency: exchangeRate.currency)
    }
}
