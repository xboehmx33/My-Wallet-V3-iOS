// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import ToolKit

@available(*, deprecated, message: "This should not be used when new quote model becomes stable")
struct OldQuoteResponse: Decodable {
    let time: String
    let rate: String
    let rateWithoutFee: String
    let fee: String
}

struct QuoteResponse: Decodable {
    struct FeeDetails: Decodable {
        enum FeeFlag: String, Decodable {
            case newUserWaiver = "NEW_USER_WAIVER"
        }

        let feeWithoutPromo: String
        let fee: String
        let feeFlags: [FeeFlag]
    }

    struct SettlementDetails: Decodable {
        enum AvailabilityType: String, Decodable {
            case instant = "INSTANT"
            case regular = "REGULAR"
            case unavailable = "UNAVAILABLE"
        }

        let availability: AvailabilityType
    }

    let quoteId: String
    let quoteMarginPercent: Double
    let quoteCreatedAt: String
    let quoteExpiresAt: String

    /// The price is in destination currency specified by the `brokerage/quote` request
    let price: String

    let networkFee: String?
    let staticFee: String?
    let feeDetails: FeeDetails
    let settlementDetails: SettlementDetails
    let sampleDepositAddress: String?
}

public struct Quote {

    // MARK: - Types

    enum SetupError: Error {
        case dateFormatting
        case feeParsing
        case priceParsing
        case wrongCurrenciesPair
    }

    // MARK: - Properties

    public let quoteId: String?
    public let quoteCreatedAt: Date
    public let quoteExpiresAt: Date
    public let fee: MoneyValue
    public let rate: MoneyValue
    public let estimatedDestinationAmount: MoneyValue
    public let estimatedSourceAmount: MoneyValue

    private let dateFormatter = DateFormatter.sessionDateFormat

    // MARK: - Setup

    @available(*, deprecated, message: "This should not be used when new quote model becomes stable")
    init(
        sourceCurrency: Currency,
        destinationCurrency: Currency,
        value: MoneyValue,
        response: OldQuoteResponse
    ) throws {
        guard let quoteCreated = dateFormatter.date(from: response.time) else {
            throw SetupError.dateFormatting
        }
        guard let rate = BigInt(response.rate) else {
            throw SetupError.priceParsing
        }
        guard let feeRateMinor = Decimal(string: response.fee) else {
            throw SetupError.feeParsing
        }
        guard let source = sourceCurrency as? FiatCurrency,
              let destination = destinationCurrency as? CryptoCurrency
        else {
            throw SetupError.wrongCurrenciesPair
        }
        let majorEstimatedAmount: Decimal = value.amount.decimalDivision(divisor: rate)
        // Decimal string interpolation always uses '.' (full stop) as decimal separator, because of that we will use US locale.
        let estimatedCryptoAmount = CryptoValue.create(major: majorEstimatedAmount, currency: destination)
        estimatedDestinationAmount = estimatedCryptoAmount.moneyValue
        let feeAmountMinor = feeRateMinor * estimatedDestinationAmount.displayMajorValue
        // Decimal string interpolation always uses '.' (full stop) as decimal separator, because of that we will use US locale.
        fee = FiatValue.create(minor: feeAmountMinor, currency: source).moneyValue
        quoteCreatedAt = quoteCreated
        let fiatRate = FiatValue.create(minor: rate, currency: source)
        self.rate = fiatRate.moneyValue
        estimatedSourceAmount = estimatedCryptoAmount.convertToFiatValue(exchangeRate: fiatRate).moneyValue

        // Unused
        quoteId = nil
        quoteExpiresAt = quoteCreatedAt
    }

    init(
        sourceCurrency: Currency,
        destinationCurrency: Currency,
        value: MoneyValue,
        response: QuoteResponse
    ) throws {
        quoteId = response.quoteId

        // formatting dates
        guard let quoteCreatedDate = dateFormatter.date(from: response.quoteCreatedAt),
              let quoteExpiresDate = dateFormatter.date(from: response.quoteExpiresAt)
        else {
            throw SetupError.dateFormatting
        }
        quoteCreatedAt = quoteCreatedDate
        quoteExpiresAt = quoteExpiresDate

        // parsing fee (source currency)
        guard let feeMinor = Decimal(string: response.feeDetails.fee) else {
            throw SetupError.feeParsing
        }
        // parsing price (destination currency)
        guard let priceMinorBigInt = BigInt(response.price) else {
            throw SetupError.priceParsing
        }

        switch (sourceCurrency, destinationCurrency) {
        // buy flow
        case (let source as FiatCurrency, let destination as CryptoCurrency):
            guard let fiatAmount = value.fiatValue else {
                fatalError("Amount must be in fiat for a buy quote")
            }
            let estimatedFiatAmount = FiatValue.create(minor: fiatAmount.amount, currency: source)
            let cryptoPriceValue = CryptoValue.create(minor: priceMinorBigInt, currency: destination)
            let cryptoPriceDisplayString = cryptoPriceValue.toDisplayString(includeSymbol: false, locale: Locale.US)
            guard let cryptoMajorAmount = Decimal(string: cryptoPriceDisplayString) else {
                throw SetupError.priceParsing
            }
            let fiatRate = FiatValue.create(major: 1 / cryptoMajorAmount, currency: source)
            let estimatedCryptoAmount = CryptoValue.create(
                major: estimatedFiatAmount.amount.decimalDivision(divisor: fiatRate.amount),
                currency: destination
            )
            estimatedSourceAmount = estimatedFiatAmount.moneyValue
            estimatedDestinationAmount = estimatedCryptoAmount.moneyValue
            rate = fiatRate.moneyValue
            fee = MoneyValue.create(minor: feeMinor, currency: .fiat(source))

        // sell flow
        case (let source as CryptoCurrency, let destination as FiatCurrency):
            guard let cryptoAmount = value.cryptoValue else {
                fatalError("Amount must be in crypto for a sell quote")
            }
            let estimatedCryptoAmount = CryptoValue.create(minor: cryptoAmount.amount, currency: source)
            let fiatPriceValue = FiatValue.create(minor: priceMinorBigInt, currency: destination)
            guard let fiatMajorAmount = Decimal(string: fiatPriceValue.displayString) else {
                throw SetupError.priceParsing
            }
            let cryptoRate = CryptoValue.create(major: 1 / fiatMajorAmount, currency: source)
            let estimatedFiatAmount = FiatValue.create(
                major: estimatedCryptoAmount.amount.decimalDivision(divisor: cryptoRate.amount),
                currency: destination
            )
            estimatedSourceAmount = estimatedCryptoAmount.moneyValue
            estimatedDestinationAmount = estimatedFiatAmount.moneyValue
            rate = cryptoRate.moneyValue
            fee = MoneyValue.create(minor: feeMinor, currency: .crypto(source))

        // swap flow
        case (let source as CryptoCurrency, let destination as CryptoCurrency):
            guard let cryptoAmount = value.cryptoValue else {
                fatalError("Amount must be in crypto for a sell quote")
            }
            let fromTokenAmount = CryptoValue.create(minor: cryptoAmount.amount, currency: source)
            let toTokenPriceValue = CryptoValue.create(minor: priceMinorBigInt, currency: destination)
            guard let toTokenMajorAmount = Decimal(string: toTokenPriceValue.displayString) else {
                throw SetupError.priceParsing
            }
            let fromTokenRate = CryptoValue.create(major: 1 / toTokenMajorAmount, currency: source)
            let toTokenAmount = CryptoValue.create(
                major: fromTokenAmount.amount.decimalDivision(divisor: fromTokenRate.amount),
                currency: destination
            )
            estimatedSourceAmount = fromTokenAmount.moneyValue
            estimatedDestinationAmount = toTokenAmount.moneyValue
            rate = fromTokenRate.moneyValue
            fee = MoneyValue.create(minor: feeMinor, currency: .crypto(source))

        default:
            fatalError("Unsupported source and destination currency pair")
        }
    }
}
