// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import FeatureInterestDomain
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import SwiftUI

struct InterestAccountDetails: Equatable, Identifiable {

    private typealias LocalizationId = LocalizationConstants.Interest.Screen.Overview

    var id: String {
        currency.code
    }

    var actionDisplayString: String {
        balance.isPositive ? LocalizationId.Action.view : LocalizationId.Action.earnInterest
    }

    var isEligible: Bool {
        ineligibilityReason == .eligible
    }

    var badgeImageViewModel: BadgeImageViewModel {
        let model: BadgeImageViewModel = .default(
            image: currency.logoResource,
            cornerRadius: .round,
            accessibilityIdSuffix: ""
        )
        model.marginOffsetRelay.accept(0)
        return model
    }

    var actions: [InterestAccountListItemAction] {
        guard isEligible else { return [] }
        return [balance.isPositive ? .viewInterestButtonTapped(self) : .earnInterestButtonTapped(self)]
    }

    let ineligibilityReason: InterestAccountIneligibilityReason
    let currency: CurrencyType
    let balance: MoneyValue
    let interestEarned: MoneyValue
    let rate: Double

    static func == (
        lhs: InterestAccountDetails,
        rhs: InterestAccountDetails
    ) -> Bool {
        lhs.currency == rhs.currency &&
            lhs.balance == rhs.balance &&
            lhs.interestEarned == rhs.interestEarned &&
            lhs.rate == rhs.rate
    }
}
