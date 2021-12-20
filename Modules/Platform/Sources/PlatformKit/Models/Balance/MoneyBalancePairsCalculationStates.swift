// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

/// This construct provides access to aggregated fiat-crypto-pair calculation states.
/// Any supported asset balance should be accessible here.
public struct MoneyBalancePairsCalculationStates {

    // MARK: - Properties

    /// Identifier for debugging purposes
    private let identifier: String

    /// Returns `MoneyValuePairCalculationState` for a given `CurrencyType`
    public subscript(currencyType: CurrencyType) -> MoneyBalancePairsCalculationState {
        statePerCurrency[currencyType]!
    }

    /// Returns all the states
    public var all: [MoneyBalancePairsCalculationState] {
        Array(statePerCurrency.values)
    }

    /// All elements must be `.calculating` for that to return `true`
    public var isCalculating: Bool {
        !all.contains { !$0.isCalculating }
    }

    /// Must contain an `.invalid` element for that to return `true`
    public var isInvalid: Bool {
        all.contains { $0.isInvalid }
    }

    /// All elements must have a value for that to return `true`
    public var isValue: Bool {
        !all.contains { !$0.isValue }
    }

    /// Some elements must have a value for that to return `true`
    public var containsValue: Bool {
        all.contains { $0.isValue }
    }

    /// Returns the portion of fiat based states
    public var fiatBaseStates: MoneyBalancePairsCalculationStates {
        MoneyBalancePairsCalculationStates(
            identifier: identifier,
            statePerCurrency: statePerCurrency.filter(\.key.isFiatCurrency)
        )
    }

    /// Returns the total fiat calculation state
    public var totalFiat: FiatValueCalculationState {
        guard !isInvalid else {
            return .invalid(.valueCouldNotBeCalculated)
        }
        guard !isCalculating else {
            return .calculating
        }
        do {
            let values = all.compactMap { $0.value?.quote.fiatValue }
            let total = try values.dropFirst().reduce(values[0], +)
            return .value(total)
        } catch {
            return .invalid(.valueCouldNotBeCalculated)
        }
    }

    // MARK: - Private Properties

    private var statePerCurrency: [CurrencyType: MoneyBalancePairsCalculationState] = [:]

    // MARK: - Setup

    public init(
        identifier: String,
        statePerCurrency: [CurrencyType: MoneyBalancePairsCalculationState]
    ) {
        self.identifier = identifier
        self.statePerCurrency = statePerCurrency
    }

    public func filter(by currencyTypes: [CurrencyType]) -> MoneyBalancePairsCalculationStates {
        MoneyBalancePairsCalculationStates(
            identifier: identifier,
            statePerCurrency: statePerCurrency.filter { currencyTypes.contains($0.key) }
        )
    }
}

extension MoneyBalancePairsCalculationStates: CustomDebugStringConvertible {
    public var debugDescription: String {
        "MoneyBalancePairsCalculationStates identifier: \(identifier). states: \(statePerCurrency)"
    }
}
