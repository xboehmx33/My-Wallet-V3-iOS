// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxRelay
import RxSwift
import ToolKit

final class SwapActivityDetailsPresenter: DetailsScreenPresenterAPI {

    // MARK: - Types

    private typealias BadgeItem = BadgeAsset.Value.Interaction.BadgeItem
    private typealias BadgeType = BadgeItem.BadgeType
    private typealias LocalizedString = LocalizationConstants.Activity.Details
    private typealias AccessibilityId = Accessibility.Identifier.Activity.Details

    // MARK: - DetailsScreenPresenterAPI

    let cells: [DetailsScreen.CellType]

    let titleViewRelay: BehaviorRelay<Screen.Style.TitleView> = .init(value: .none)

    let navigationBarAppearance: DetailsScreen.NavigationBarAppearance = .defaultDark

    let navigationBarLeadingButtonAction: DetailsScreen.BarButtonAction = .default

    let navigationBarTrailingButtonAction: DetailsScreen.BarButtonAction = .default

    let reloadRelay: PublishRelay<Void> = .init()

    // MARK: - Private Properties

    private let disposeBag = DisposeBag()

    // MARK: Private Properties (LabelContentPresenting)

    private let cryptoAmountLabelPresenter: LabelContentPresenting

    // MARK: Private Properties (Badge Model)

    private let badgesModel = MultiBadgeViewModel()
    private let statusBadge: DefaultBadgeAssetPresenter = .init()

    // MARK: Private Properties (LineItemCellPresenting)

    private let orderIDPresenter: LineItemCellPresenting
    private let dateCreatedPresenter: LineItemCellPresenting
    private let exchangeRatePresenter: LineItemCellPresenting
    private let totalPresenter: LineItemCellPresenting
    private let amountFromPresenter: LineItemCellPresenting
    private let amountForPresenter: LineItemCellPresenting
    private let toPresenter: LineItemCellPresenting
    private let fromPresenter: LineItemCellPresenting

    // MARK: - Init

    init(
        event: SwapActivityItemEvent,
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve()
    ) {
        titleViewRelay.accept(.text(value: LocalizedString.Title.swap))

        cryptoAmountLabelPresenter = DefaultLabelContentPresenter(
            knownValue: event.amounts.withdrawal.displayString,
            descriptors: .h1(accessibilityIdPrefix: AccessibilityId.cryptoAmountPrefix)
        )

        let statusDescription = event.status.localizedDescription
        let badgeType: BadgeType
        switch event.status {
        case .complete:
            badgeType = .verified
        case .delayed,
             .inProgress,
             .none,
             .pendingRefund:
            badgeType = .default(accessibilitySuffix: statusDescription)
        case .expired,
             .failed,
             .refunded:
            badgeType = .destructive
        }
        badgesModel.badgesRelay.accept([statusBadge])
        statusBadge.interactor.stateRelay.accept(
            .loaded(
                next: .init(
                    type: badgeType,
                    description: statusDescription
                )
            )
        )

        orderIDPresenter = TransactionalLineItem.orderId(event.identifier).defaultCopyablePresenter(
            analyticsRecorder: analyticsRecorder,
            accessibilityIdPrefix: AccessibilityId.lineItemPrefix
        )

        let date = DateFormatter.elegantDateFormatter.string(from: event.date)
        dateCreatedPresenter = TransactionalLineItem.date(date).defaultPresenter(
            accessibilityIdPrefix: AccessibilityId.lineItemPrefix
        )

        let amountFrom = event.amounts.withdrawal.displayString
        amountFromPresenter = TransactionalLineItem.amount(amountFrom).defaultPresenter(
            accessibilityIdPrefix: AccessibilityId.lineItemPrefix
        )

        let amountFor = event.amounts.deposit.displayString
        amountForPresenter = TransactionalLineItem.for(amountFor).defaultPresenter(
            accessibilityIdPrefix: AccessibilityId.lineItemPrefix
        )

        let pair = MoneyValuePair(base: event.amounts.withdrawal, quote: event.amounts.deposit)
        let exchangeRate = pair.exchangeRate
        let exchangeRateString = "\(exchangeRate.quote.displayString) / \(exchangeRate.base.displayCode)"
        exchangeRatePresenter = TransactionalLineItem.exchangeRate(exchangeRateString).defaultPresenter(
            accessibilityIdPrefix: AccessibilityId.lineItemPrefix
        )

        let total = event.amounts.fiatValue.displayString
        totalPresenter = TransactionalLineItem.total(total).defaultPresenter(
            accessibilityIdPrefix: AccessibilityId.lineItemPrefix
        )

        switch event.isNonCustodial {
        case true:
            let destination = event.kind.withdrawalAddress
            toPresenter = TransactionalLineItem.to(destination).defaultCopyablePresenter(
                analyticsRecorder: analyticsRecorder,
                accessibilityIdPrefix: AccessibilityId.lineItemPrefix
            )

            let source = event.depositTxHash ?? ""
            fromPresenter = TransactionalLineItem.from(source).defaultCopyablePresenter(
                analyticsRecorder: analyticsRecorder,
                accessibilityIdPrefix: AccessibilityId.lineItemPrefix
            )
        case false:
            let destination = "\(event.pair.outputCurrencyType.displayCode) \(LocalizedString.wallet)"
            toPresenter = TransactionalLineItem.to(destination).defaultPresenter(
                accessibilityIdPrefix: AccessibilityId.lineItemPrefix
            )

            let source = "\(event.pair.inputCurrencyType.displayCode) \(LocalizedString.wallet)"
            fromPresenter = TransactionalLineItem.from(source).defaultPresenter(
                accessibilityIdPrefix: AccessibilityId.lineItemPrefix
            )
        }

        cells = [
            .label(cryptoAmountLabelPresenter),
            .badges(badgesModel),
            .separator,
            .lineItem(orderIDPresenter),
            .separator,
            .lineItem(dateCreatedPresenter),
            .separator,
            .lineItem(amountFromPresenter),
            .separator,
            .lineItem(amountForPresenter),
            .separator,
            .lineItem(exchangeRatePresenter),
            .separator,
            .lineItem(totalPresenter),
            .separator,
            .lineItem(toPresenter),
            .separator,
            .lineItem(fromPresenter),
            .separator
        ]
    }
}
