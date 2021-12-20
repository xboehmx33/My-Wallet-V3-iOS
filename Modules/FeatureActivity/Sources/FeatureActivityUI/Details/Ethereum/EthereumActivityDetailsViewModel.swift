// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import ERC20Kit
import EthereumKit
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit

struct EthereumActivityDetailsViewModel: Equatable {

    private typealias LocalizedString = LocalizationConstants.Activity.Details

    struct Confirmation: Equatable {
        fileprivate static let empty: Confirmation = .init(
            needConfirmation: false,
            title: "",
            factor: 1,
            statusBadge: EthereumActivityDetailsViewModel.statusBadge(for: .confirmed)
        )
        let needConfirmation: Bool
        let title: String
        let factor: Float
        let statusBadge: BadgeAsset.Value.Interaction.BadgeItem
    }

    struct Amounts: Equatable {
        fileprivate static let empty: Amounts = .init(fee: .empty, trade: .empty, gasFor: nil, isGas: false)

        struct Value: Equatable {
            fileprivate static let empty: Value = .init(cryptoAmount: "", value: "")
            let cryptoAmount: String
            let value: String
        }

        let fee: Value
        let trade: Value
        let gasFor: Value?
        let isGas: Bool
    }

    let confirmation: Confirmation
    let dateCreated: String
    let to: String
    let from: String
    let amounts: Amounts
    let fee: String
    let note: String

    init(details: EthereumActivityItemEventDetails, price: FiatValue?, note: String? = nil) {
        confirmation = Confirmation(
            needConfirmation: details.confirmation.needConfirmation,
            // swiftlint:disable line_length
            title: "\(details.confirmation.confirmations) \(LocalizedString.of) \(details.confirmation.requiredConfirmations) \(LocalizedString.confirmations)",
            factor: details.confirmation.factor,
            statusBadge: EthereumActivityDetailsViewModel.statusBadge(for: details.confirmation.status)
        )
        dateCreated = DateFormatter.elegantDateFormatter.string(from: details.createdAt)
        to = details.to.publicKey
        from = details.from.publicKey

        let gas = ERC20ContractGasActivityModel(details: details)
        amounts = EthereumActivityDetailsViewModel.amounts(details: details, gas: gas, price: price)
        fee = "\(amounts.fee.cryptoAmount) / \(amounts.fee.value)"

        self.note = note ?? ""
    }

    private static func amounts(
        details: EthereumActivityItemEventDetails,
        gas: ERC20ContractGasActivityModel?,
        price: FiatValue?
    ) -> Amounts {

        func value(cryptoValue: CryptoValue) -> Amounts.Value {
            let cryptoAmount = cryptoValue.displayString
            let value: String
            if let price = price {
                value = cryptoValue.convertToFiatValue(exchangeRate: price).displayString
            } else {
                value = ""
            }
            return Amounts.Value(cryptoAmount: cryptoAmount, value: value)
        }

        var gasFor: Amounts.Value?

        if let gasCryptoValue = gas?.cryptoValue {
            gasFor = value(cryptoValue: gasCryptoValue)
        }

        return Amounts(
            fee: value(cryptoValue: details.fee),
            trade: value(cryptoValue: details.amount),
            gasFor: gasFor,
            isGas: gas != nil
        )
    }

    private static func statusBadge(for state: EthereumTransactionState) -> BadgeAsset.Value.Interaction.BadgeItem {
        switch state {
        case .confirmed:
            return .init(type: .verified, description: LocalizedString.completed)
        case .pending:
            return .init(
                type: .default(accessibilitySuffix: "Pending"),
                description: LocalizedString.pending
            )
        case .replaced:
            return .init(type: .verified, description: LocalizedString.replaced)
        }
    }
}
