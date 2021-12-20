// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RIBs
import RxCocoa
import RxSwift
import UIKit

protocol WithdrawAmountPageBuildable {
    func build(listener: WithdrawAmountPageListener, beneficiary: Beneficiary) -> WithdrawAmountPageRouter
}

final class WithdrawAmountPageBuilder: WithdrawAmountPageBuildable {

    private let currency: FiatCurrency
    private let fiatCurrencyService: FiatCurrencyServiceAPI

    init(
        currency: FiatCurrency,
        fiatCurrencyService: FiatCurrencyServiceAPI = resolve()
    ) {
        self.currency = currency
        self.fiatCurrencyService = fiatCurrencyService
    }

    func build(listener: WithdrawAmountPageListener, beneficiary: Beneficiary) -> WithdrawAmountPageRouter {
        let displayBundle: DisplayBundle = .withdraw(currency: currency)

        let singleViewInteractor = SingleAmountInteractor(
            currencyService: fiatCurrencyService,
            inputCurrency: currency
        )
        let singleViewPresenter = SingleAmountPresenter(interactor: singleViewInteractor)
        let amountView = SingleAmountView(presenter: singleViewPresenter)

        let digitPadViewModel = provideDigitPadViewModel()
        let continueButtonViewModel = ButtonViewModel.primary(with: displayBundle.strings.ctaButton)
        let topSelectionButtonViewModel = SelectionButtonViewModel(showSeparator: false)

        let viewController = WithdrawAmountViewController(
            displayBundle: displayBundle,
            devicePresenterType: DevicePresenter.type,
            digitPadViewModel: digitPadViewModel,
            continueButtonViewModel: continueButtonViewModel,
            topSelectionButtonViewModel: topSelectionButtonViewModel,
            amountViewProvider: amountView
        )

        let validationService = WithdrawAmountValidationService(
            fiatCurrency: currency,
            beneficiary: beneficiary
        )
        let feeService = WithdrawalFeeService()
        let interactor = WithdrawAmountPageInteractor(
            presenter: viewController,
            fiatCurrency: currency,
            beneficiary: beneficiary,
            amountInteractor: singleViewInteractor,
            withdrawalFeeService: feeService,
            validationService: validationService
        )
        interactor.listener = listener
        let router = WithdrawAmountPageRouter(
            interactor: interactor,
            viewController: viewController
        )
        return router
    }

    // MARK: - Private methods

    private func provideDigitPadViewModel() -> DigitPadViewModel {
        let highlightColor = Color.black.withAlphaComponent(0.08)
        let model = DigitPadButtonViewModel(
            content: .label(text: MoneyValueInputScanner.Constant.decimalSeparator, tint: .titleText),
            background: .init(highlightColor: highlightColor)
        )
        return DigitPadViewModel(
            padType: .number,
            customButtonViewModel: model,
            contentTint: .titleText,
            buttonHighlightColor: highlightColor
        )
    }
}
