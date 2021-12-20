// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitectureExtensions
import ComposableNavigation
import Localization
import MoneyKit
import PlatformKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit

// swiftlint:disable type_body_length
final class BuyCheckoutScreenContentReducer: CheckoutScreenContentReducing {

    // MARK: - Types

    private typealias LocalizedString = LocalizationConstants.SimpleBuy.Checkout
    private typealias LocalizedLineItem = LocalizationConstants.LineItem.Transactional
    private typealias LocalizedSummary = LocalizedString.Summary
    private typealias AccessibilityLineItem = Accessibility.Identifier.LineItem
    private typealias AccessibilityId = Accessibility.Identifier.SimpleBuy.Checkout
    private typealias LineItem = TransactionalLineItem

    // MARK: - Properties

    let title: String
    let cells: [DetailsScreen.CellType]

    // MARK: - View Models

    let continueButtonViewModel: ButtonViewModel
    let cancelButtonViewModel: ButtonViewModel?
    private(set) var transferDetailsButtonViewModel: ButtonViewModel?

    // MARK: - Cell Presenters

    private let orderIdLineItemCellPresenter: DefaultLineItemCellPresenter = LineItem.orderId().defaultPresenter(
        accessibilityIdPrefix: AccessibilityId.lineItemPrefix
    )
    private let dateLineItemCellPresenter: DefaultLineItemCellPresenter = LineItem.date().defaultPresenter(
        accessibilityIdPrefix: AccessibilityId.lineItemPrefix
    )
    private let totalCostLineItemCellPresenter: DefaultLineItemCellPresenter = LineItem.totalCost().defaultPresenter(
        accessibilityIdPrefix: AccessibilityId.lineItemPrefix
    )
    private let totalLineItemCellPresenter: DefaultLineItemCellPresenter = LineItem.total().defaultPresenter(
        accessibilityIdPrefix: AccessibilityId.lineItemPrefix
    )
    private let buyingFeeLineItemCellPresenter: DefaultLineItemCellPresenter = LineItem.buyingFee().defaultPresenter(
        accessibilityIdPrefix: AccessibilityId.lineItemPrefix
    )
    private let feeLineItemCellPresenter: DefaultLineItemCellPresenter = LineItem.fee().defaultPresenter(
        accessibilityIdPrefix: AccessibilityId.lineItemPrefix
    )
    private let paymentMethodLineItemCellPresenter: DefaultLineItemCellPresenter =
        LineItem.paymentMethod().defaultPresenter(
            accessibilityIdPrefix: AccessibilityId.lineItemPrefix
        )
    private let exchangeRateLineItemCellPresenter: DefaultLineItemCellPresenter =
        LineItem.exchangeRate().defaultPresenter(
            accessibilityIdPrefix: AccessibilityId.lineItemPrefix
        )
    private let statusLineItemCellPresenter: DefaultLineItemCellPresenter =
        LineItem.status(LocalizedLineItem.pending).defaultPresenter(
            accessibilityIdPrefix: AccessibilityId.lineItemPrefix
        )

    private let availableToTradeInstantlyItemCellPresenter: DefaultLineItemCellPresenter =
        LineItem.availableToTrade(LocalizedLineItem.instantly).defaultPresenter(
            accessibilityIdPrefix: AccessibilityId.lineItemPrefix
        )

    private let cryptoAmountLabelPresenter = DefaultLabelContentPresenter(
        knownValue: " ",
        descriptors: .h1(accessibilityIdPrefix: AccessibilityId.cryptoAmountPrefix)
    )
    private let fiatAmountLabelPresenter = DefaultLabelContentPresenter(
        knownValue: " ",
        descriptors: .h1(accessibilityIdPrefix: AccessibilityId.fiatAmountPrefix)
    )

    private let cryptoPriceItemCellPresenter: DefaultLineItemCellPresenter

    private static func notice(data: CheckoutData) -> LabelContent {
        LabelContent(
            text: data.order.paymentMethod.checkoutNotice(currencyType: data.outputCurrency),
            font: .main(.medium, 12),
            color: .descriptionText,
            accessibility: .id(AccessibilityLineItem.Base.disclaimerLabel)
        )
    }

    private static func title(data: CheckoutData) -> String {
        switch data.order.paymentMethod {
        case .card:
            if data.hasCardCheckoutMade {
                return LocalizedString.Title.orderDetails
            } else {
                return LocalizedString.Title.checkout
            }
        case .bankAccount, .funds, .bankTransfer:
            if data.order.isPendingConfirmation {
                return LocalizedString.Title.checkout
            } else {
                return LocalizedString.Title.orderDetails
            }
        }
    }

    private static func continueButton(data: CheckoutData) -> ButtonViewModel {
        let title: String
        switch data.order.paymentMethod {
        case .card:
            if data.hasCardCheckoutMade {
                title = data.isPending3DS ?
                    LocalizedSummary.completePaymentButton :
                    LocalizedSummary.continueButtonPrefix
            } else {
                title = LocalizedSummary.buyButtonTitle
            }
        case .bankAccount, .funds, .bankTransfer:
            if data.order.isPendingConfirmation {
                title = LocalizedSummary.buyButtonTitle
            } else {
                title = LocalizedSummary.continueButtonPrefix
            }
        }
        return .primary(with: title)
    }

    private static func cancelButton(data: CheckoutData) -> ButtonViewModel? {
        switch (data.order.paymentMethod, data.hasCardCheckoutMade, data.isPendingDeposit) {
        case (.card, true, _):
            return nil
        case (.bankTransfer, _, true):
            return nil
        case (.card, false, _),
             (.bankAccount, _, _),
             (.bankTransfer, _, _),
             (.funds, _, _):
            return .cancel(with: LocalizationConstants.cancel)
        }
    }

    // MARK: - Accessors

    func setupDidSucceed(with data: CheckoutInteractionData) {
        var formattedTime = ""
        if let creationDate = data.creationDate {
            formattedTime = DateFormatter.elegantDateFormatter.string(from: creationDate)
        }
        dateLineItemCellPresenter.interactor.description.stateRelay.accept(
            .loaded(next: .init(text: formattedTime))
        )
        buyingFeeLineItemCellPresenter.interactor.description.stateRelay.accept(
            .loaded(next: .init(text: data.fee.displayString))
        )
        feeLineItemCellPresenter.interactor.description.stateRelay.accept(
            .loaded(next: .init(text: data.fee.displayString))
        )

        cryptoAmountLabelPresenter.interactor.stateRelay.accept(
            .loaded(next: .init(text: data.amount.toDisplayString(includeSymbol: true)))
        )

        exchangeRateLineItemCellPresenter.interactor.description.stateRelay.accept(
            .loaded(next: .init(text: data.exchangeRate?.toDisplayString(includeSymbol: true) ?? ""))
        )
        cryptoPriceItemCellPresenter.interactor.description.stateRelay.accept(
            .loaded(next: .init(text: data.exchangeRate?.toDisplayString(includeSymbol: true) ?? ""))
        )
        orderIdLineItemCellPresenter.interactor.description.stateRelay.accept(
            .loaded(next: .init(text: data.orderId))
        )

        let localizedPaymentMethod: String
        switch data.paymentMethod {
        case .funds:
            localizedPaymentMethod =
                "\(LocalizedLineItem.Funds.prefix) \(data.fee.displayCode) \(LocalizedLineItem.Funds.suffix)"
        case .card:
            localizedPaymentMethod = "\(data.card?.label ?? "") \(data.card?.displaySuffix ?? "")"
        case .bankAccount:
            localizedPaymentMethod = LocalizedLineItem.bankTransfer
        case .bankTransfer:
            if let bankTransferData = data.bankTransferData, let account = bankTransferData.account {
                localizedPaymentMethod = "\(account.bankName) \(account.type.title) \(account.number)"
            } else {
                localizedPaymentMethod = LocalizedLineItem.bankTransfer
            }
        }

        paymentMethodLineItemCellPresenter.interactor.description.stateRelay.accept(
            .loaded(next: .init(text: localizedPaymentMethod))
        )
    }

    // swiftlint:disable function_body_length
    init(data: CheckoutData) {

        // MARK: Presenters Setup

        let totalCost = data.order.inputValue.displayString
        totalCostLineItemCellPresenter.interactor.description.stateRelay.accept(
            .loaded(next: .init(text: totalCost))
        )

        totalLineItemCellPresenter.interactor.description.stateRelay.accept(
            .loaded(next: .init(text: totalCost))
        )

        fiatAmountLabelPresenter.interactor.stateRelay.accept(
            .loaded(next: .init(text: "\(totalCost) \(LocalizedSummary.of) \(data.outputCurrency.displayCode)"))
        )

        cryptoPriceItemCellPresenter = LineItem.cryptoPrice(data.cryptoValue?.displayCode ?? LocalizedLineItem.price)
            .defaultPresenter(accessibilityIdPrefix: AccessibilityId.lineItemPrefix)

        // MARK: Title Setup

        title = BuyCheckoutScreenContentReducer.title(data: data)

        // MARK: Buttons Setup

        continueButtonViewModel = BuyCheckoutScreenContentReducer.continueButton(data: data)
        cancelButtonViewModel = BuyCheckoutScreenContentReducer.cancelButton(data: data)

        switch (
            data.order.paymentMethod,
            data.hasCardCheckoutMade,
            data.isPendingDepositBankWire,
            data.isPendingDeposit
        ) {
        case (.card, true, _, _):

            // MARK: Cells Setup

            cells = [
                .label(cryptoAmountLabelPresenter),
                .separator,
                .lineItem(orderIdLineItemCellPresenter),
                .separator,
                .lineItem(dateLineItemCellPresenter),
                .separator,
                .lineItem(exchangeRateLineItemCellPresenter),
                .separator,
                .lineItem(paymentMethodLineItemCellPresenter),
                .separator,
                .lineItem(buyingFeeLineItemCellPresenter),
                .separator,
                .lineItem(totalCostLineItemCellPresenter),
                .separator,
                .lineItem(statusLineItemCellPresenter),
                .staticLabel(BuyCheckoutScreenContentReducer.notice(data: data))
            ]
        case (.card, false, _, _),
             (.bankAccount, _, false, _):

            // MARK: Cells Setup

            cells = [
                .label(cryptoAmountLabelPresenter),
                .separator,
                .lineItem(orderIdLineItemCellPresenter),
                .separator,
                .lineItem(dateLineItemCellPresenter),
                .separator,
                .lineItem(totalCostLineItemCellPresenter),
                .separator,
                .lineItem(buyingFeeLineItemCellPresenter),
                .separator,
                .lineItem(paymentMethodLineItemCellPresenter),
                .separator,
                .staticLabel(BuyCheckoutScreenContentReducer.notice(data: data))
            ]
        case (.funds, _, _, _):

            cells = [
                .label(cryptoAmountLabelPresenter),
                .separator,
                .lineItem(orderIdLineItemCellPresenter),
                .separator,
                .lineItem(dateLineItemCellPresenter),
                .separator,
                .lineItem(totalCostLineItemCellPresenter),
                .separator,
                .lineItem(buyingFeeLineItemCellPresenter),
                .separator,
                .lineItem(paymentMethodLineItemCellPresenter),
                .separator,
                .staticLabel(BuyCheckoutScreenContentReducer.notice(data: data))
            ]

        case (.bankAccount, _, true, _):

            // MARK: Cells Setup

            transferDetailsButtonViewModel = .primary(
                with: LocalizedString.Button.transferDetails,
                accessibilityId: AccessibilityId.Button.transferDetails
            )

            cells = [
                .label(fiatAmountLabelPresenter),
                .buttons([transferDetailsButtonViewModel!]),
                .separator,
                .lineItem(orderIdLineItemCellPresenter),
                .separator,
                .lineItem(dateLineItemCellPresenter),
                .separator,
                .lineItem(totalCostLineItemCellPresenter),
                .separator,
                .lineItem(buyingFeeLineItemCellPresenter),
                .separator,
                .lineItem(paymentMethodLineItemCellPresenter),
                .separator,
                .staticLabel(BuyCheckoutScreenContentReducer.notice(data: data))
            ]
        case (.bankTransfer, _, _, false):
            cells = [
                .label(cryptoAmountLabelPresenter),
                .separator,
                .lineItem(cryptoPriceItemCellPresenter),
                .separator,
                .lineItem(feeLineItemCellPresenter),
                .separator,
                .lineItem(totalLineItemCellPresenter),
                .separator,
                .lineItem(paymentMethodLineItemCellPresenter),
                .separator,
                .lineItem(availableToTradeInstantlyItemCellPresenter),
                .separator,
                .staticLabel(BuyCheckoutScreenContentReducer.notice(data: data))
            ]
        case (.bankTransfer, _, _, true):
            cells = [
                .label(cryptoAmountLabelPresenter),
                .separator,
                .lineItem(orderIdLineItemCellPresenter),
                .separator,
                .lineItem(dateLineItemCellPresenter),
                .separator,
                .lineItem(cryptoPriceItemCellPresenter),
                .separator,
                .lineItem(feeLineItemCellPresenter),
                .separator,
                .lineItem(totalLineItemCellPresenter),
                .separator,
                .lineItem(paymentMethodLineItemCellPresenter),
                .separator,
                .staticLabel(BuyCheckoutScreenContentReducer.notice(data: data))
            ]
        }
    }
}

extension PlatformKit.PaymentMethod.MethodType {
    fileprivate func checkoutNotice(currencyType: CurrencyType) -> String {
        typealias LocalizedString = LocalizationConstants.SimpleBuy.Checkout.Notice
        switch self {
        case .card:
            return LocalizedString.cards
        case .funds:
            return LocalizedString.funds
        case .bankAccount:
            return "\(LocalizedString.BankTransfer.prefix) \(currencyType.displayCode) \(LocalizedString.BankTransfer.suffix)"
        case .bankTransfer:
            return LocalizedString.linkedBankCard
        }
    }
}
