// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import ToolKit

public struct PendingTransaction: Equatable {

    public enum EngineStateKey: String {
        case quoteSubscription
        case userTiers
        case xlmMemo
        case bitpayTimer
        case gasPrice
        case gasLimit
    }

    public var amount: MoneyValue
    // The source account actionable balance minus the fees for the current fee level.
    public var available: MoneyValue
    public var selectedFiatCurrency: FiatCurrency
    public var feeSelection: FeeSelection
    public var feeAmount: MoneyValue
    public var feeForFullAvailable: MoneyValue
    /// The list of `TransactionConfirmation`.
    /// To update this value, use methods `update(confirmations:)` and `insert(confirmations:)`
    public private(set) var confirmations: [TransactionConfirmation] = []

    public var validationState: TransactionValidationState = .uninitialized
    public var engineState: [EngineStateKey: Any] = [:]

    private var _limits: Reference<TransactionLimits?> // this struct has become too big for Swift to handle :(
    public var limits: TransactionLimits? {
        get {
            _limits.value
        }
        set {
            _limits = Reference(newValue)
        }
    }

    // TODO: remove limits below in favour of limits struct above
    private var minimumLimit: MoneyValue?
    private var maximumLimit: MoneyValue?
    private var maximumDailyLimit: MoneyValue?
    private var maximumAnnualLimit: MoneyValue?

    public init(
        amount: MoneyValue,
        available: MoneyValue,
        feeAmount: MoneyValue,
        feeForFullAvailable: MoneyValue,
        feeSelection: FeeSelection,
        selectedFiatCurrency: FiatCurrency,
        limits: TransactionLimits? = nil,
        minimumLimit: MoneyValue? = nil,
        maximumLimit: MoneyValue? = nil,
        maximumDailyLimit: MoneyValue? = nil,
        maximumAnnualLimit: MoneyValue? = nil
    ) {
        self.amount = amount
        self.available = available
        self.feeAmount = feeAmount
        self.feeForFullAvailable = feeForFullAvailable
        self.feeSelection = feeSelection
        self.selectedFiatCurrency = selectedFiatCurrency
        _limits = Reference(limits)
        self.minimumLimit = minimumLimit
        self.maximumLimit = maximumLimit
        self.maximumDailyLimit = maximumDailyLimit
        self.maximumAnnualLimit = maximumAnnualLimit
    }

    public func update(validationState: TransactionValidationState) -> PendingTransaction {
        var copy = self
        copy.validationState = validationState
        return copy
    }

    public func update(amount: MoneyValue) -> PendingTransaction {
        var copy = self
        copy.amount = amount
        return copy
    }

    public func update(amount: MoneyValue, available: MoneyValue) -> PendingTransaction {
        var copy = self
        copy.amount = amount
        copy.available = available
        return copy
    }

    public func update(selectedFeeLevel: FeeLevel) -> PendingTransaction {
        var copy = self
        copy.feeSelection = copy.feeSelection.update(selectedLevel: selectedFeeLevel)
        return copy
    }

    public func update(availableFeeLevels: Set<FeeLevel>) -> PendingTransaction {
        var copy = self
        copy.feeSelection = copy.feeSelection.update(availableFeeLevels: availableFeeLevels)
        return copy
    }

    public func update(selectedFeeLevel: FeeLevel, customFeeAmount: MoneyValue?) -> PendingTransaction {
        var copy = self
        copy.feeSelection = copy.feeSelection
            .update(customAmount: customFeeAmount, selectedLevel: selectedFeeLevel)
        return copy
    }

    public func update(
        amount: MoneyValue,
        available: MoneyValue,
        fee: MoneyValue,
        feeForFullAvailable: MoneyValue
    ) -> PendingTransaction {
        var copy = self
        copy.amount = amount
        copy.available = available
        copy.feeAmount = fee
        copy.feeForFullAvailable = feeForFullAvailable
        return copy
    }

    /// Insert a `TransactionConfirmation`, replacing any previous value with the same confirmation type.
    public func insert(confirmation: TransactionConfirmation, prepend: Bool = false) -> PendingTransaction {
        var copy = self
        if let idx = copy.confirmations.firstIndex(where: { $0.bareCompare(to: confirmation) }) {
            copy.confirmations.replaceSubrange(idx...idx, with: [confirmation])
        } else {
            prepend ? copy.confirmations.insert(confirmation, at: 0) : copy.confirmations.append(confirmation)
        }
        return copy
    }

    /// Appends content of the given list into the current confirmations list.
    public func insert(confirmations: [TransactionConfirmation]) -> PendingTransaction {
        var copy = self
        copy.confirmations.append(contentsOf: confirmations)
        return copy
    }

    /// Update (replace) the confirmations list with the given value.
    public func update(confirmations: [TransactionConfirmation]) -> PendingTransaction {
        var copy = self
        copy.confirmations = confirmations
        return copy
    }

    /// Removes confirmations of the given type from the confirmations list.
    public func remove(optionType: TransactionConfirmation.Kind) -> PendingTransaction {
        var copy = self
        copy.confirmations = confirmations.filter { $0.type != optionType }
        return copy
    }

    public func hasFeeLevelChanged(newLevel: FeeLevel, newAmount: MoneyValue) -> Bool {
        feeLevel != newLevel || (feeLevel == .custom && newAmount != customFeeAmount)
    }

    // MARK: - Equatable

    public static func == (lhs: PendingTransaction, rhs: PendingTransaction) -> Bool {
        lhs.amount == rhs.amount
            && lhs.feeAmount == rhs.feeAmount
            && lhs.available == rhs.available
            && lhs.feeSelection == rhs.feeSelection
            && lhs.feeForFullAvailable == rhs.feeForFullAvailable
            && lhs.selectedFiatCurrency == rhs.selectedFiatCurrency
            && lhs.feeLevel == rhs.feeLevel
            && lhs.confirmations == rhs.confirmations
            && lhs.limits == rhs.limits
            && lhs.minimumLimit == rhs.minimumLimit
            && lhs.maximumLimit == rhs.maximumLimit
            && lhs.validationState == rhs.validationState
            && lhs.maximumDailyLimit == rhs.maximumDailyLimit
            && lhs.maximumAnnualLimit == rhs.maximumAnnualLimit
    }
}

// MARK: - Limtis

extension PendingTransaction {

    public var normalizedLimits: TransactionLimits {
        TransactionLimits(
            currencyType: minLimit.currencyType,
            minimum: minLimit,
            maximum: maxLimit,
            maximumDaily: maxDailyLimit,
            maximumAnnual: maxAnnualLimit,
            effectiveLimit: limits?.effectiveLimit ?? EffectiveLimit(timeframe: .single, value: maxLimit),
            suggestedUpgrade: limits?.suggestedUpgrade
        )
    }

    public var minLimit: MoneyValue {
        limits?.minimum ?? minimumLimit ?? .zero(currency: amount.currency)
    }

    public var maxLimit: MoneyValue {
        limits?.maximum ?? maximumLimit ?? available
    }

    public var maxDailyLimit: MoneyValue {
        limits?.maximumDaily ?? maximumDailyLimit ?? maxLimit
    }

    public var maxAnnualLimit: MoneyValue {
        limits?.maximumAnnual ?? maximumAnnualLimit ?? maxDailyLimit
    }

    /// The minimum spending limit
    public var minSpendable: MoneyValue {
        limits?.minimum ?? minimumLimit ?? .zero(currency: amount.currency)
    }

    /// The maximum amount the user can spend. We compare the amount entered to the
    /// `limits.minimum` or `maximumLimit` as `CryptoValues` and return whichever is smaller.
    public var maxSpendable: MoneyValue {
        guard let availableMaximumLimit = try? maxLimit - feeAmount else {
            return available
        }
        let minAvailable: MoneyValue = (try? .min(available, availableMaximumLimit)) ?? available
        return (try? .max(.zero(currency: amount.currency), minAvailable)) ?? available // ensure the value is >= 0
    }

    public var maxSpendableDaily: MoneyValue {
        (try? .min(maxDailyLimit, maxSpendable)) ?? .zero(currency: amount.currency)
    }

    public var maxSpendableAnnually: MoneyValue {
        (try? .min(maxAnnualLimit, maxSpendable)) ?? .zero(currency: amount.currency)
    }
}

// MARK: - Fees

extension PendingTransaction {

    public var feeLevel: FeeLevel {
        feeSelection.selectedLevel
    }

    public var availableFeeLevels: Set<FeeLevel> {
        feeSelection.availableLevels
    }

    public var customFeeAmount: MoneyValue? {
        feeSelection.customAmount
    }
}

// MARK: - Term Options

extension PendingTransaction {

    public var termsOptionValue: Bool {
        guard let confirmation = confirmations
            .first(where: { $0.type == .agreementInterestTandC })
        else {
            return false
        }
        guard case .termsOfService(let option) = confirmation else { return false }
        return option.value
    }

    public var agreementOptionValue: Bool {
        guard let confirmation = confirmations
            .first(where: { $0.type == .agreementInterestTransfer })
        else {
            return false
        }
        guard case .transferAgreement(let option) = confirmation else { return false }
        return option.value
    }
}

// MARK: - Init Conveniences

extension PendingTransaction {

    public static func zero(currencyType: CurrencyType) -> PendingTransaction {
        .init(
            amount: .zero(currency: currencyType),
            available: .zero(currency: currencyType),
            feeAmount: .zero(currency: currencyType),
            feeForFullAvailable: .zero(currency: currencyType),
            // TODO: Handle alternate currency types
            feeSelection: .empty(asset: currencyType),
            selectedFiatCurrency: .USD
        )
    }
}
