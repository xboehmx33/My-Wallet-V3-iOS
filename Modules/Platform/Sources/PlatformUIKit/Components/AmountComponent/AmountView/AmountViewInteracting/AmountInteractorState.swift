// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit

/// The `Interactor` state of an `AmountViewable` view.
/// At the time of this writing this includes a `SingleAmountView`
/// and an `AmountTranslationView`.
public enum AmountInteractorState {

    /// Show nothing.
    case empty

    /// The amount entered is within the appropriate bounds
    /// for completing a transaction
    case inBounds

    /// Show a warning. Tapping the warning triggers
    /// the closure.
    case warning(message: String, action: () -> Void)

    /// Show an error message
    case error(message: String)

    /// The max limit has been exceeded
    case maxLimitExceeded(MoneyValue)

    /// The amount entered is below the users minimum
    case underMinLimit(MoneyValue)
}
