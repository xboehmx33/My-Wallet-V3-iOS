// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit
import ToolKit

public enum PaymentMethodPayloadType: String, CaseIterable, Encodable {
    case card = "PAYMENT_CARD"
    case bankAccount = "BANK_ACCOUNT"
    case bankTransfer = "BANK_TRANSFER"
    case funds = "FUNDS"
}

/// The available payment methods
public struct PaymentMethod: Equatable, Comparable {

    public enum MethodType: Equatable, Comparable {
        /// Card payment method
        case card(Set<CardType>)

        /// Bank account payment method (linking via wire transfer)
        case bankAccount(CurrencyType)

        /// Bank transfer payment method (linking via ACH or Open Banking)
        case bankTransfer(CurrencyType)

        /// Funds payment method
        case funds(CurrencyType)

        public var isCard: Bool {
            switch self {
            case .card:
                return true
            case .bankAccount, .bankTransfer, .funds:
                return false
            }
        }

        public var isFunds: Bool {
            switch self {
            case .funds:
                return true
            case .bankAccount, .bankTransfer, .card:
                return false
            }
        }

        public var isBankAccount: Bool {
            switch self {
            case .bankAccount:
                return true
            case .funds, .card, .bankTransfer:
                return false
            }
        }

        public var isBankTransfer: Bool {
            switch self {
            case .bankTransfer:
                return true
            case .funds, .card, .bankAccount:
                return false
            }
        }

        public var rawType: PaymentMethodPayloadType {
            switch self {
            case .card:
                return .card
            case .bankAccount:
                return .bankAccount
            case .funds:
                return .funds
            case .bankTransfer:
                return .bankTransfer
            }
        }

        var sortIndex: Int {
            switch self {
            case .bankTransfer:
                return 0
            case .card:
                return 1
            case .funds:
                return 2
            case .bankAccount:
                return 3
            }
        }

        public init?(
            type: PaymentMethodPayloadType,
            subTypes: [String],
            currency: FiatCurrency,
            supportedFiatCurrencies: [FiatCurrency]
        ) {
            switch type {
            case .card:
                let cardTypes = Set(subTypes.compactMap { CardType(rawValue: $0) })
                /// Addition validation - make sure that if `.card` is returned
                /// at least one sub type is included. e.g: "VISA".
                guard !cardTypes.isEmpty else { return nil }
                self = .card(cardTypes)
            case .bankAccount:
                guard supportedFiatCurrencies.contains(currency) else {
                    return nil
                }
                self = .bankAccount(currency.currencyType)
            case .bankTransfer:
                guard supportedFiatCurrencies.contains(currency) else {
                    return nil
                }
                self = .bankTransfer(currency.currencyType)
            case .funds:
                guard supportedFiatCurrencies.contains(currency) else {
                    return nil
                }
                self = .funds(currency.currencyType)
            }
        }

        public init(type: PaymentMethodPayloadType, currency: CurrencyType) {
            switch type {
            case .card:
                self = .card([])
            case .bankAccount:
                self = .bankAccount(currency)
            case .bankTransfer:
                self = .bankTransfer(currency)
            case .funds:
                self = .funds(currency)
            }
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.rawType == rhs.rawType
        }

        public static func < (lhs: PaymentMethod.MethodType, rhs: PaymentMethod.MethodType) -> Bool {
            lhs.sortIndex < rhs.sortIndex
        }

        /// Helper method to determine if the passed MethodType is the same as self
        /// - Parameter otherType: A `MethodType` for the comparison
        /// - Returns: `True` if it is the same MethodType as the passed one otherwise false
        public func isSame(as otherType: MethodType) -> Bool {
            switch (self, otherType) {
            case (.card(let lhs), .card(let rhs)):
                return lhs == rhs
            case (.bankAccount(let currencyLhs), .bankAccount(let currencyRhs)):
                return currencyLhs == currencyRhs
            case (.bankTransfer(let currencyLhs), .bankTransfer(let currencyRhs)):
                return currencyLhs == currencyRhs
            case (.funds(let currencyLhs), .funds(let currencyRhs)):
                return currencyLhs == currencyRhs
            default:
                return false
            }
        }
    }

    /// The type of the payment method
    public let type: MethodType

    /// `True` if the user is eligible to use the payment method, otherwise false
    public let isEligible: Bool

    /// `true` if the payment method can be shown to the user
    public let isVisible: Bool

    /// The maximum value of payment using that method
    public let max: FiatValue

    /// The minimum value of payment using that method
    public let min: FiatValue

    /// The maximum value of payment using that method
    /// for a single day
    public let maxDaily: FiatValue

    /// The maximum value of payment using that method
    /// for the year
    public let maxAnnual: FiatValue

    /// The `FiatCurrency` supported by the `PaymentMethod`
    public var fiatCurrency: FiatCurrency {
        switch type {
        case .bankAccount(let currency),
             .bankTransfer(let currency),
             .funds(let currency):
            guard let fiat = currency.fiatCurrency else {
                impossible("Payment method types should use fiat.")
            }
            return fiat
        case .card:
            return max.currency
        }
    }

    public static func == (lhs: PaymentMethod, rhs: PaymentMethod) -> Bool {
        lhs.type == rhs.type
    }

    public static func < (lhs: PaymentMethod, rhs: PaymentMethod) -> Bool {
        lhs.type < rhs.type
    }

    public var label: String {
        let localizedString: String
        let localizationSpace = LocalizationConstants.SimpleBuy.AddPaymentMethodSelectionScreen.self
        switch type {
        case .bankAccount:
            localizedString = localizationSpace.Types.bankAccount

        case .bankTransfer:
            localizedString = localizationSpace.Types.bankWireTitle

        case .card:
            localizedString = localizationSpace.Types.cardTitle

        case .funds:
            localizedString = localizationSpace.DepositCash.title
        }
        return localizedString
    }

    public init(
        type: MethodType,
        max: FiatValue,
        min: FiatValue,
        maxDaily: FiatValue? = nil,
        maxAnnual: FiatValue? = nil,
        isEligible: Bool,
        isVisible: Bool
    ) {
        self.type = type
        self.max = max
        self.min = min
        self.maxDaily = maxDaily ?? max
        self.maxAnnual = maxAnnual ?? max
        self.isEligible = isEligible
        self.isVisible = isVisible
    }
}
