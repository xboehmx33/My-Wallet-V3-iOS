//
//  TransactionFlowDescriptor.swift
//  TransactionUIKit
//
//  Created by Alex McGregor on 11/13/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import Localization
import PlatformKit

final class TransactionFlowDescriptor {

    private typealias LocalizedString = LocalizationConstants.Transaction
    
    enum EnterAmountScreen {
        static func headerTitle(state: TransactionState) throws -> String {
            "\(LocalizedString.Swap.swap): \(try state.moneyValueFromSource().displayString)"
        }

        static func headerSubtitle(state: TransactionState) throws -> String {
            "\(LocalizedString.receive): \(try state.moneyValueFromDestination().displayString)"
        }
    }
    enum AccountPicker {
        static func sourceTitle(action: AssetAction) -> String {
            switch action {
            case .swap:
                return LocalizedString.Swap.swap
            case .deposit,
                 .receive,
                 .sell,
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
            case .deposit,
                 .receive,
                 .sell,
                 .send,
                 .viewActivity,
                 .withdraw:
                return ""
            }
        }

        static func destinationTitle(action: AssetAction) -> String {
            switch action {
            case .swap:
                return LocalizedString.receive
            case .deposit,
                 .receive,
                 .sell,
                 .send,
                 .viewActivity,
                 .withdraw:
                return ""
            }
        }

        static func destinationSubtitle(action: AssetAction) -> String {
            switch action {
            case .swap:
                return LocalizedString.Swap.destinationAccountPicketSubtitle
            case .deposit,
                 .receive,
                 .sell,
                 .send,
                 .viewActivity,
                 .withdraw:
                return ""
            }
        }
    }

    static let availableBalanceTitle = LocalizedString.available
    static let maxButtonTitle = LocalizedString.Swap.swapMax

    static func confirmDisclaimerVisibility(action: AssetAction) -> Bool {
        switch action {
        case .swap:
            return true
        case .deposit,
             .receive,
             .sell,
             .send,
             .viewActivity,
             .withdraw:
            return false
        }
    }

    static func confirmDisclaimerText(action: AssetAction) -> String {
        switch action {
        case .swap:
            return LocalizedString.Swap.confirmationDisclaimer
        case .deposit,
             .receive,
             .sell,
             .send,
             .viewActivity,
             .withdraw:
            return ""
        }
    }
}
