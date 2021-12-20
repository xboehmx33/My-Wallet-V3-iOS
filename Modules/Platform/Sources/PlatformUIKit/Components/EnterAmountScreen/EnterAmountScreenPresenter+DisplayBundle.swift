// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Localization
import MoneyKit
import PlatformKit
import ToolKit

extension EnterAmountScreenPresenter {

    /// Contains localized strings, analytics events and accessibility identifiers
    public struct DisplayBundle {

        public struct Colors {
            public let digitPadTopSeparator: Color
            public let bottomAuxiliaryItemSeparator: Color

            public init(
                digitPadTopSeparator: Color,
                bottomAuxiliaryItemSeparator: Color
            ) {
                self.digitPadTopSeparator = digitPadTopSeparator
                self.bottomAuxiliaryItemSeparator = bottomAuxiliaryItemSeparator
            }
        }

        public struct Events {
            public let didAppear: [AnalyticsEvent]
            public let confirmSuccess: AnalyticsEvent
            public let confirmFailure: AnalyticsEvent
            public let confirmTapped: (CurrencyType, MoneyValue, CryptoCurrency, [String: String]) -> [AnalyticsEvent]
            public let sourceAccountChanged: (String) -> AnalyticsEvent

            public init(
                didAppear: [AnalyticsEvent],
                confirmSuccess: AnalyticsEvent,
                confirmFailure: AnalyticsEvent,
                confirmTapped: @escaping (CurrencyType, MoneyValue, CryptoCurrency, [String: String]) -> [AnalyticsEvent],
                sourceAccountChanged: @escaping (String) -> AnalyticsEvent
            ) {
                self.didAppear = didAppear
                self.confirmSuccess = confirmSuccess
                self.confirmFailure = confirmFailure
                self.confirmTapped = confirmTapped
                self.sourceAccountChanged = sourceAccountChanged
            }
        }

        public struct Strings {
            public let title: String
            public let ctaButton: String
            public let bottomAuxiliaryItemSeparatorTitle: String

            public init(
                title: String,
                ctaButton: String,
                bottomAuxiliaryItemSeparatorTitle: String
            ) {
                self.title = title
                self.ctaButton = ctaButton
                self.bottomAuxiliaryItemSeparatorTitle = bottomAuxiliaryItemSeparatorTitle
            }
        }

        public struct AccessibilityIdentifiers {
            public let bottomAuxiliaryItemSeparatorTitle: String

            public init(bottomAuxiliaryItemSeparatorTitle: String) {
                self.bottomAuxiliaryItemSeparatorTitle = bottomAuxiliaryItemSeparatorTitle
            }
        }

        public let amountDisplayBundle: AmountTranslationPresenter.DisplayBundle
        public let strings: Strings
        public let colors: Colors
        public let events: Events
        public let accessibilityIdentifiers: AccessibilityIdentifiers

        public init(
            strings: Strings,
            colors: Colors,
            events: Events,
            accessibilityIdentifiers: AccessibilityIdentifiers,
            amountDisplayBundle: AmountTranslationPresenter.DisplayBundle
        ) {
            self.strings = strings
            self.colors = colors
            self.events = events
            self.accessibilityIdentifiers = accessibilityIdentifiers
            self.amountDisplayBundle = amountDisplayBundle
        }
    }
}
