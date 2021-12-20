// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import ToolKit

/// Calculation state with an associated `MoneyValueBalancePairs`.
/// It represents the calculation state of the total balance.
@available(*, deprecated, message: "[TICKET]: IOS-3884")
public typealias MoneyBalancePairsCalculationState = ValueCalculationState<MoneyValueBalancePairs>

/// Calculation state with an associated `MoneyValuePair`
/// It represents the calculation state of base and quote amounts.
@available(*, deprecated, message: "[TICKET]: IOS-3884")
public typealias MoneyValuePairCalculationState = ValueCalculationState<MoneyValuePair>

/// Calculation state with an associated `FiatValue`
public typealias FiatValueCalculationState = ValueCalculationState<FiatValue>
