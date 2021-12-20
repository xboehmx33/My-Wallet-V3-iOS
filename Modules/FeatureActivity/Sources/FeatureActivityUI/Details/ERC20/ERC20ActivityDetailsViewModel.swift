// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import ERC20Kit
import EthereumKit
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit

struct ERC20ActivityDetailsViewModel: Equatable {

    private typealias LocalizedString = LocalizationConstants.Activity.Details

    struct Confirmation: Equatable {
        fileprivate static let empty: Confirmation = .init(
            needConfirmation: false,
            title: "",
            factor: 1,
            statusBadge: ERC20ActivityDetailsViewModel.statusBadge(for: .confirmed)
        )
        let needConfirmation: Bool
        let title: String
        let factor: Float
        let statusBadge: BadgeAsset.Value.Interaction.BadgeItem
    }

    struct Amounts: Equatable {
        fileprivate static let empty: Amounts = .init(fee: .empty, gasFor: nil)

        struct Value: Equatable {
            fileprivate static let empty: Value = .init(cryptoAmount: "", value: "")
            let cryptoAmount: String
            let value: String
        }

        let fee: Value
        let gasFor: Value?
    }

    let confirmation: Confirmation
    let dateCreated: String
    let to: String?
    let from: String
    let amounts: Amounts
    let fee: String

    init(details: EthereumActivityItemEventDetails, price: FiatValue?, feePrice: FiatValue?) {
        confirmation = Confirmation(
            needConfirmation: details.confirmation.needConfirmation,
            // swiftlint:disable line_length
            title: "\(details.confirmation.confirmations) \(LocalizedString.of) \(details.confirmation.requiredConfirmations) \(LocalizedString.confirmations)",
            factor: details.confirmation.factor,
            statusBadge: ERC20ActivityDetailsViewModel.statusBadge(for: details.confirmation.status)
        )
        dateCreated = DateFormatter.elegantDateFormatter.string(from: details.createdAt)

        let gas = ERC20ContractGasActivityModel(details: details)
        amounts = ERC20ActivityDetailsViewModel.amounts(details: details, gas: gas, price: price, feePrice: feePrice)

        to = gas?.to?.publicKey
        from = details.from.publicKey

        fee = "\(amounts.fee.cryptoAmount) / \(amounts.fee.value)"
    }

    private static func amounts(
        details: EthereumActivityItemEventDetails,
        gas: ERC20ContractGasActivityModel?,
        price: FiatValue?,
        feePrice: FiatValue?
    ) -> Amounts {
        func value(cryptoValue: CryptoValue, price: FiatValue?) -> Amounts.Value {
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
            gasFor = value(cryptoValue: gasCryptoValue, price: price)
        }

        return Amounts(
            fee: value(cryptoValue: details.fee, price: feePrice),
            gasFor: gasFor
        )
    }

    private static func statusBadge(for state: EthereumTransactionState) -> BadgeAsset.Value.Interaction.BadgeItem {
        switch state {
        case .confirmed:
            return .init(type: .verified, description: LocalizedString.completed)
        case .pending:
            return .init(type: .default(accessibilitySuffix: "Pending"), description: LocalizedString.pending)
        case .replaced:
            return .init(type: .verified, description: LocalizedString.replaced)
        }
    }
}
