// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import Localization
import PlatformKit

private typealias LocalizedStrings = LocalizationConstants.KYC.LimitsOverview.Feature

extension LimitedTradeFeature {

    var icon: Icon {
        switch id {
        case .send:
            return Icon.send
        case .receive:
            return Icon.qrCode
        case .swap:
            return Icon.swap
        case .sell:
            return Icon.sell
        case .buyWithCard:
            return Icon.creditcard
        case .buyWithBankAccount:
            return Icon.bank
        case .withdraw:
            return Icon.bank
        case .rewards:
            return Icon.interest
        }
    }

    var title: String {
        switch id {
        case .send:
            return LocalizedStrings.featureName_send
        case .receive:
            return LocalizedStrings.featureName_receive
        case .swap:
            return LocalizedStrings.featureName_swap
        case .sell:
            return LocalizedStrings.featureName_sell
        case .buyWithCard:
            return LocalizedStrings.featureName_buyWithCard
        case .buyWithBankAccount:
            return LocalizedStrings.featureName_buyWithBankAccount
        case .withdraw:
            return LocalizedStrings.featureName_withdraw
        case .rewards:
            return LocalizedStrings.featureName_rewards
        }
    }

    var message: String? {
        let text: String?
        switch id {
        case .send:
            text = LocalizedStrings.toTradingAccountsOnlyNote
        case .receive:
            text = LocalizedStrings.fromTradingAccountsOnlyNote
        default:
            text = nil
        }
        return text
    }

    var valueDisplayString: String {
        guard enabled else {
            return LocalizedStrings.disabled
        }
        guard let limit = limit else {
            return LocalizedStrings.enabled
        }
        return limit.displayString
    }
}

extension LimitedTradeFeature.PeriodicLimit {

    var displayString: String {
        guard let value = value else {
            return LocalizedStrings.unlimited
        }
        let format: String
        switch period {
        case .day:
            format = LocalizedStrings.limitedPerDay
        case .month:
            format = LocalizedStrings.limitedPerMonth
        case .year:
            format = LocalizedStrings.limitedPerYear
        }
        return String.localizedStringWithFormat(format, value.shortDisplayString)
    }
}
