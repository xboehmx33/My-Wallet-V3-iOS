// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import MoneyKit
import PlatformKit
import ToolKit

enum TransactionFlowDescriptor {

    private typealias LocalizedString = LocalizationConstants.Transaction

    enum EnterAmountScreen {

        private static func formatForHeader(moneyValue: MoneyValue) -> String {
            moneyValue.displayString
        }

        static func headerTitle(state: TransactionState) -> String {
            switch state.action {
            case .swap:
                let prefix = "\(LocalizedString.Swap.swap): "
                guard let moneyValue = try? state.moneyValueFromSource().get() else {
                    return prefix
                }
                return prefix + formatForHeader(moneyValue: moneyValue)
            case .send:
                let prefix = "\(LocalizedString.Send.from): "
                guard let source = state.source else {
                    return prefix
                }
                return prefix + source.label
            case .withdraw:
                return LocalizedString.Withdraw.availableToWithdrawTitle
            case .interestTransfer,
                 .interestWithdraw:
                guard let account = state.source else {
                    return ""
                }
                return LocalizedString.from + ": \(account.label)"
            case .deposit:
                return LocalizedString.Deposit.dailyLimit
            case .buy:
                guard let source = state.source, let destination = state.destination else {
                    return LocalizedString.Buy.title
                }
                return "\(LocalizedString.Buy.title) \(destination.currencyType.displayCode) using \(source.label)"
            case .sell:
                return [
                    LocalizedString.Sell.headerTitlePrefix,
                    state.source?.label
                ].compactMap { $0 }.joined(separator: " ")
            case .sign,
                 .receive,
                 .viewActivity:
                unimplemented()
            }
        }

        static func headerSubtitle(state: TransactionState) -> String {
            switch state.action {
            case .swap:
                let prefix = "\(LocalizedString.receive): "
                guard let moneyValue = try? state.moneyValueFromDestination().get() else {
                    return prefix
                }
                return prefix + formatForHeader(moneyValue: moneyValue)
            case .send:
                let prefix = "\(LocalizedString.Send.to): "
                guard let destination = state.destination else {
                    return prefix
                }
                if let address = destination as? CryptoReceiveAddress {
                    return prefix + address.address
                }
                guard let account = destination as? BlockchainAccount else {
                    return prefix
                }
                return prefix + account.label
            case .withdraw:
                return formatForHeader(moneyValue: state.maxSpendable)
            case .interestTransfer,
                 .interestWithdraw:
                guard let destination = state.destination else {
                    return ""
                }
                guard let account = destination as? BlockchainAccount else {
                    return ""
                }
                return LocalizedString.to + ": \(account.label)"
            case .deposit:
                return "\(state.maxDaily.displayString)"
            case .buy:
                let prefix = "\(LocalizedString.Buy.title):"
                guard let destination = state.destination else {
                    return prefix
                }
                return "\(prefix) \(destination.currencyType.displayCode) \(destination.label)"
            case .sell:
                return [
                    LocalizedString.Sell.headerSubtitlePrefix,
                    state.destination?.label
                ].compactMap { $0 }.joined(separator: " ")
            case .sign,
                 .receive,
                 .viewActivity:
                unimplemented()
            }
        }
    }

    enum AccountPicker {
        static func sourceTitle(action: AssetAction) -> String {
            switch action {
            case .swap:
                return LocalizedString.Swap.swap
            case .deposit:
                return LocalizedString.Deposit.linkedBanks
            case .buy:
                return LocalizedString.Buy.selectSourceTitle
            case .sell:
                return LocalizedString.Sell.selectSourceTitle
            case .interestWithdraw:
                return LocalizedString.Withdraw.withdrawTo
            case .interestTransfer:
                return LocalizedString.Transfer.transferFrom
            case .sign,
                 .receive,
                 .send,
                 .viewActivity,
                 .withdraw:
                return ""
            }
        }

        static func sourceSubtitle(action: AssetAction) -> String {
            switch action {
            case .swap:
                return LocalizedString.Swap.sourceAccountPicketSubtitle
            case .sell:
                return LocalizedString.Sell.selectSourceSubtitle
            case .sign,
                 .withdraw,
                 .deposit,
                 .receive,
                 .buy,
                 .send,
                 .viewActivity,
                 .interestWithdraw,
                 .interestTransfer:
                return ""
            }
        }

        static func destinationTitle(action: AssetAction) -> String {
            switch action {
            case .swap:
                return LocalizedString.receive
            case .withdraw,
                 .interestWithdraw:
                return LocalizedString.Withdraw.withdrawTo
            case .buy:
                return LocalizedString.Buy.selectDestinationTitle
            case .sell:
                return LocalizedString.Sell.title
            case .interestTransfer:
                return LocalizedString.Transfer.transferFrom
            case .sign,
                 .deposit,
                 .receive,
                 .send,
                 .viewActivity:
                return ""
            }
        }

        static func destinationSubtitle(action: AssetAction) -> String {
            switch action {
            case .swap:
                return LocalizedString.Swap.destinationAccountPicketSubtitle
            case .sell:
                return LocalizedString.Sell.selectDestinationTitle
            case .sign,
                 .deposit,
                 .receive,
                 .buy,
                 .send,
                 .viewActivity,
                 .withdraw,
                 .interestWithdraw,
                 .interestTransfer:
                return ""
            }
        }
    }

    enum TargetSelection {
        static func navigationTitle(action: AssetAction) -> String {
            switch action {
            case .swap:
                return LocalizedString.newSwap
            case .send:
                return LocalizedString.Send.send
            case .withdraw,
                 .interestWithdraw:
                return LocalizedString.Withdraw.withdraw
            case .interestTransfer:
                return LocalizedString.transfer
            case .sign,
                 .deposit,
                 .receive,
                 .buy,
                 .sell,
                 .viewActivity:
                unimplemented()
            }
        }
    }

    static let networkFee = LocalizedString.networkFee
    static let availableBalanceTitle = LocalizedString.available
    static let maxButtonTitle = LocalizedString.Swap.swapMax

    static func maxButtonTitle(action: AssetAction) -> String {
        action.name + " \(LocalizedString.max)"
    }

    static func confirmDisclaimerVisibility(action: AssetAction) -> Bool {
        switch action {
        case .swap,
             .withdraw,
             .interestWithdraw,
             .buy:
            return true
        case .sign,
             .deposit,
             .receive,
             .sell,
             .send,
             .viewActivity,
             .interestTransfer:
            return false
        }
    }

    static func confirmDisclaimerText(
        action: AssetAction,
        currencyCode: String = "",
        accountLabel: String = ""
    ) -> String {
        switch action {
        case .swap:
            return LocalizedString.Swap.confirmationDisclaimer
        case .withdraw:
            return LocalizedString.Withdraw.confirmationDisclaimer
        case .buy:
            return LocalizedString.Buy.confirmationDisclaimer
        case .interestWithdraw:
            return String(
                format: LocalizedString.InterestWithdraw.confirmationDisclaimer,
                currencyCode,
                accountLabel
            )
        case .sign,
             .deposit,
             .receive,
             .sell,
             .send,
             .viewActivity,
             .interestWithdraw,
             .interestTransfer:
            return ""
        }
    }
}
