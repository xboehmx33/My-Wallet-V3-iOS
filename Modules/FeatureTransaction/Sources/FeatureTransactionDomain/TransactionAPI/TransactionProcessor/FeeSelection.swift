// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

public struct FeeSelection: Equatable {
    public var selectedLevel: FeeLevel = .none
    public var customAmount: MoneyValue?
    public var availableLevels: Set<FeeLevel> = [.none]
    public var customLevelRates: FeeLevelRates?
    public var feeState: FeeState?
    public var asset: CurrencyType?

    public init(
        selectedLevel: FeeLevel,
        availableLevels: Set<FeeLevel>,
        asset: CurrencyType? = nil
    ) {
        self.selectedLevel = selectedLevel
        self.availableLevels = availableLevels
        self.asset = asset
    }

    public func update(customAmount: MoneyValue?, selectedLevel: FeeLevel) -> FeeSelection {
        precondition(availableLevels.contains(selectedLevel))
        var copy = self
        copy.customAmount = customAmount
        copy.selectedLevel = selectedLevel
        return copy
    }

    public func update(selectedLevel: FeeLevel) -> FeeSelection {
        precondition(availableLevels.contains(selectedLevel))
        var copy = self
        copy.selectedLevel = selectedLevel
        return copy
    }

    public func update(availableFeeLevels: Set<FeeLevel>) -> FeeSelection {
        var copy = self
        copy.availableLevels = availableFeeLevels
        return copy
    }

    public static func empty(asset: CurrencyType?) -> FeeSelection {
        .init(selectedLevel: .none, availableLevels: [.none], asset: asset)
    }
}
