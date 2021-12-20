// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit

enum InterestNoEligibleWalletsAction: Equatable {

    /// Start the buy flow after the screen is dismissed
    case startBuyAfterDismissal(CryptoCurrency)

    /// The user should be routed to buy when the screen is dismissed
    /// if the user has tapped the `Buy` button
    case startBuyOnDismissalIfNeeded

    /// The user tapped the `Buy` button
    case startBuyTapped

    /// The close button is tapped.
    case dismissNoEligibleWalletsScreen
}
