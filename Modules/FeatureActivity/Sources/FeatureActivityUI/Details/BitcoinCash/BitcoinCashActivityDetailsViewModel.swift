// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BitcoinCashKit
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit

struct BitcoinCashActivityDetailsViewModel: Equatable {

    private typealias LocalizedString = LocalizationConstants.Activity.Details

    struct Confirmation: Equatable {
        fileprivate static let empty: Confirmation = .init(
            needConfirmation: false,
            title: "",
            factor: 1,
            statusBadge: BitcoinCashActivityDetailsViewModel.statusBadge(needConfirmation: false)
        )
        let needConfirmation: Bool
        let title: String
        let factor: Float
        let statusBadge: BadgeAsset.Value.Interaction.BadgeItem
    }

    let confirmation: Confirmation
    let dateCreated: String
    let to: String
    let from: String
    let cryptoAmount: String
    let value: String
    let fee: String
    let note: String

    init(details: BitcoinCashActivityItemEventDetails, price: FiatValue?, note: String?) {
        confirmation = Confirmation(
            needConfirmation: details.confirmation.needConfirmation,
            // swiftlint:disable line_length
            title: "\(details.confirmation.confirmations) \(LocalizedString.of) \(details.confirmation.requiredConfirmations) \(LocalizedString.confirmations)",
            factor: details.confirmation.factor,
            statusBadge: BitcoinCashActivityDetailsViewModel.statusBadge(needConfirmation: details.confirmation.needConfirmation)
        )
        dateCreated = DateFormatter.elegantDateFormatter.string(from: details.createdAt)
        from = details.from.publicKey
        to = details.to.publicKey

        cryptoAmount = details.amount.displayString
        if let price = price {
            value = details.amount.convertToFiatValue(exchangeRate: price).displayString
            fee = "\(details.fee.displayString) / \(details.fee.convertToFiatValue(exchangeRate: price).displayString)"
        } else {
            value = ""
            fee = details.fee.displayString
        }

        self.note = note ?? ""
    }

    private static func statusBadge(needConfirmation: Bool) -> BadgeAsset.Value.Interaction.BadgeItem {
        if needConfirmation {
            return .init(
                type: .default(accessibilitySuffix: "Pending"),
                description: LocalizedString.pending
            )
        } else {
            return .init(type: .verified, description: LocalizedString.completed)
        }
    }
}
