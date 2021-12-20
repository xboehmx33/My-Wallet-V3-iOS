// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import Localization
import MoneyKit
import PlatformKit
import RxAnalyticsKit
import RxCocoa
import RxSwift
import ToolKit

final class IneligibleCurrencyScreenPresenter {

    // MARK: - Types

    private typealias AnalyticsEvent = AnalyticsEvents.SimpleBuy
    private typealias LocalizationString = LocalizationConstants.SimpleBuy.Ineligible
    private typealias AccessibilityID = Accessibility.Identifier.SimpleBuy.IneligibleCurrency

    // MARK: - Rx

    let dismissalRelay = PublishRelay<Void>()
    let restartRelay = PublishRelay<Void>()

    // MARK: - Public Properties

    let thumbnail = UIImage(named: "region-error-icon", in: .platformUIKit, compatibleWith: nil)!
    let changeCurrencyButtonViewModel: ButtonViewModel
    let viewHomeButtonViewModel: ButtonViewModel
    let titleLabelContent: LabelContent
    let descriptionLabelContent: LabelContent

    // MARK: - Private Properties

    private let stateService: StateServiceAPI
    private let disposeBag = DisposeBag()

    init(
        currency: FiatCurrency,
        stateService: StateServiceAPI,
        analyticsRecording: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.stateService = stateService
        titleLabelContent = .init(
            text: "\(currency.name) \(LocalizationString.title)",
            font: .main(.semibold, 20.0),
            color: .titleText,
            alignment: .center,
            accessibility: .id(AccessibilityID.titleLabel)
        )

        descriptionLabelContent = .init(
            text: "\(LocalizationString.description) \(currency.name).",
            font: .main(.medium, 14.0),
            color: .titleText,
            alignment: .center,
            accessibility: .id(AccessibilityID.descriptionLabel)
        )

        viewHomeButtonViewModel = .secondary(
            with: LocalizationString.viewHome,
            accessibilityId: AccessibilityID.viewHome
        )

        viewHomeButtonViewModel.tapRelay
            .record(analyticsEvent: AnalyticsEvent.sbUnsupportedViewHome, using: analyticsRecording)
            .bindAndCatch(to: dismissalRelay)
            .disposed(by: disposeBag)

        changeCurrencyButtonViewModel = .primary(
            with: LocalizationString.changeCurrency,
            accessibilityId: AccessibilityID.changeCurrency
        )

        changeCurrencyButtonViewModel.tapRelay
            .record(analyticsEvent: AnalyticsEvent.sbUnsupportedChangeCurrency, using: analyticsRecording)
            .bindAndCatch(to: restartRelay)
            .disposed(by: disposeBag)
    }

    func changeCurrency() {
        stateService.reselectCurrency()
    }

    func dismiss() {
        stateService.previousRelay.accept(())
    }
}
