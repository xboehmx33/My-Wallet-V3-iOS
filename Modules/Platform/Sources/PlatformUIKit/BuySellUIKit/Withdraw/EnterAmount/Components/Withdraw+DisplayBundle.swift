// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Localization
import MoneyKit
import PlatformKit
import ToolKit

struct DisplayBundle {

    struct Colors {
        let digitPadTopSeparator: Color
        let bottomAuxiliaryItemSeparator: Color

        init(
            digitPadTopSeparator: Color,
            bottomAuxiliaryItemSeparator: Color
        ) {
            self.digitPadTopSeparator = digitPadTopSeparator
            self.bottomAuxiliaryItemSeparator = bottomAuxiliaryItemSeparator
        }
    }

    struct Events {
        let didAppear: AnalyticsEvent
        let minTapped: AnalyticsEvent
        let maxTapped: AnalyticsEvent
        let confirmSuccess: AnalyticsEvent
        let confirmFailure: AnalyticsEvent
        let confirmTapped: (CurrencyType, MoneyValue, [String: String]) -> AnalyticsEvent
        let sourceAccountChanged: (String) -> AnalyticsEvent

        init(
            didAppear: AnalyticsEvent,
            minTapped: AnalyticsEvent,
            maxTapped: AnalyticsEvent,
            confirmSuccess: AnalyticsEvent,
            confirmFailure: AnalyticsEvent,
            confirmTapped: @escaping (CurrencyType, MoneyValue, [String: String]) -> AnalyticsEvent,
            sourceAccountChanged: @escaping (String) -> AnalyticsEvent
        ) {
            self.didAppear = didAppear
            self.minTapped = minTapped
            self.maxTapped = maxTapped
            self.confirmSuccess = confirmSuccess
            self.confirmFailure = confirmFailure
            self.confirmTapped = confirmTapped
            self.sourceAccountChanged = sourceAccountChanged
        }
    }

    struct Strings {
        let title: String
        let ctaButton: String
        let bottomAuxiliaryItemSeparatorTitle: String
        let useMin: String
        let useMax: String

        init(
            title: String,
            ctaButton: String,
            bottomAuxiliaryItemSeparatorTitle: String,
            useMin: String,
            useMax: String
        ) {
            self.title = title
            self.ctaButton = ctaButton
            self.bottomAuxiliaryItemSeparatorTitle = bottomAuxiliaryItemSeparatorTitle
            self.useMin = useMin
            self.useMax = useMax
        }
    }

    struct AccessibilityIdentifiers {
        let bottomAuxiliaryItemSeparatorTitle: String

        init(bottomAuxiliaryItemSeparatorTitle: String) {
            self.bottomAuxiliaryItemSeparatorTitle = bottomAuxiliaryItemSeparatorTitle
        }
    }

    let strings: Strings
    let colors: Colors
    let events: Events
    let accessibilityIdentifiers: AccessibilityIdentifiers

    init(
        strings: Strings,
        colors: Colors,
        events: Events,
        accessibilityIdentifiers: AccessibilityIdentifiers
    ) {
        self.strings = strings
        self.colors = colors
        self.events = events
        self.accessibilityIdentifiers = accessibilityIdentifiers
    }
}

extension DisplayBundle {

    static func withdraw(currency: Currency) -> DisplayBundle {
        typealias LocalizedString = LocalizationConstants.FiatWithdrawal.EnterAmountScreen
        typealias AnalyticsEvent = AnalyticsEvents.SimpleBuy
        typealias AccessibilityId = Accessibility.Identifier.SimpleBuy.SellScreen

        let strings = Strings(
            title: String(format: LocalizedString.title, currency.displayCode),
            ctaButton: LocalizedString.ctaButton,
            bottomAuxiliaryItemSeparatorTitle: "",
            useMin: "",
            useMax: LocalizedString.useMax
        )

        let colors = Colors(
            digitPadTopSeparator: .lightBorder,
            bottomAuxiliaryItemSeparator: .clear
        )

        // TODO: Add correct Analytics Event
        let events = Events(
            didAppear: AnalyticsEvent.sbBuyFormShown,
            minTapped: AnalyticsEvent.sbBuyFormMinClicked,
            maxTapped: AnalyticsEvent.sbBuyFormMaxClicked,
            confirmSuccess: AnalyticsEvent.sbBuyFormConfirmSuccess,
            confirmFailure: AnalyticsEvent.sbBuyFormConfirmFailure,
            confirmTapped: { currencyType, amount, additionalParameters in
                AnalyticsEvent.sbBuyFormConfirmClick(
                    currencyCode: currencyType.code,
                    amount: amount.toDisplayString(includeSymbol: true),
                    additionalParameters: additionalParameters
                )
            },
            sourceAccountChanged: { AnalyticsEvent.sbBuyFormCryptoChanged(asset: $0) }
        )
        let accessibilityIdentifiers = AccessibilityIdentifiers(
            bottomAuxiliaryItemSeparatorTitle: ""
        )

        return DisplayBundle(
            strings: strings,
            colors: colors,
            events: events,
            accessibilityIdentifiers: accessibilityIdentifiers
        )
    }
}
