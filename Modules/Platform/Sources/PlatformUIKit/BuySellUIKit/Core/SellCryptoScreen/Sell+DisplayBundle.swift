// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Localization
import MoneyKit
import PlatformKit
import ToolKit

extension EnterAmountScreenPresenter.DisplayBundle {

    static func sell(cryptoCurrency: CryptoCurrency) -> EnterAmountScreenPresenter.DisplayBundle {

        typealias LocalizedString = LocalizationConstants.SimpleBuy.SellCryptoScreen
        typealias AnalyticsEvent = AnalyticsEvents.SimpleBuy
        typealias NewAnalyticsEvent = AnalyticsEvents.New.SimpleBuy
        typealias AccessibilityId = Accessibility.Identifier.SimpleBuy.SellScreen

        return EnterAmountScreenPresenter.DisplayBundle(
            strings: Strings(
                title: "\(LocalizedString.titlePrefix) \(cryptoCurrency.displayCode)",
                ctaButton: LocalizedString.previewSell,
                bottomAuxiliaryItemSeparatorTitle: ""
            ),
            colors: Colors(
                digitPadTopSeparator: .lightBorder,
                bottomAuxiliaryItemSeparator: .clear
            ),
            events: Events(
                didAppear: [AnalyticsEvent.sbBuyFormShown, NewAnalyticsEvent.buySellViewed(type: .sell)],
                confirmSuccess: AnalyticsEvent.sbBuyFormConfirmSuccess,
                confirmFailure: AnalyticsEvent.sbBuyFormConfirmFailure,
                confirmTapped: { currencyType, amount, _, additionalParameters in
                    [
                        AnalyticsEvent.sbBuyFormConfirmClick(
                            currencyCode: currencyType.code,
                            amount: amount.toDisplayString(includeSymbol: true),
                            additionalParameters: additionalParameters
                        )
                    ]
                },
                sourceAccountChanged: { AnalyticsEvent.sbBuyFormCryptoChanged(asset: $0) }
            ),
            accessibilityIdentifiers: AccessibilityIdentifiers(
                bottomAuxiliaryItemSeparatorTitle: ""
            ),
            amountDisplayBundle: .init(
                events: .init(
                    min: AnalyticsEvent.sbBuyFormMinClicked,
                    max: AnalyticsEvent.sbBuyFormMaxClicked
                ),
                strings: .init(
                    useMin: LocalizationConstants.Transaction.Swap.AmountPresenter.LimitView.useMin,
                    useMax: LocalizationConstants.Transaction.Swap.AmountPresenter.LimitView.useMax
                ),
                accessibilityIdentifiers: .init()
            )
        )
    }
}
