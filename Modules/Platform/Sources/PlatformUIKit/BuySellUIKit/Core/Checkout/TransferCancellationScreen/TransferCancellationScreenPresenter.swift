// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import Localization
import MoneyKit
import PlatformKit
import RxRelay
import RxSwift
import ToolKit

final class TransferCancellationScreenPresenter {

    // MARK: - Localization

    private typealias AnalyticsEvent = AnalyticsEvents.SimpleBuy
    private typealias AccessibilityIDs = Accessibility.Identifier.SimpleBuy.Cancellation
    private typealias LocalizationIDs = LocalizationConstants.SimpleBuy.TransferDetails.Cancellation

    // MARK: - Public Properties

    let titleContent: LabelContent
    let descriptionContent: LabelContent

    let noButtonViewModel: ButtonViewModel
    let yesButtonViewModel: ButtonViewModel

    let dismissalRelay = PublishRelay<Void>()

    // MARK: - Private Properties

    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let routingInteractor: TransferOrderRoutingInteracting
    private let interactor: TransferCancellationInteractor
    private let loader: LoadingViewPresenting
    private let alert: AlertViewPresenterAPI

    private let disposeBag = DisposeBag()

    init(
        routingInteractor: TransferOrderRoutingInteracting,
        currency: CurrencyType,
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve(),
        loader: LoadingViewPresenting = resolve(),
        alert: AlertViewPresenterAPI = resolve(),
        interactor: TransferCancellationInteractor
    ) {
        self.analyticsRecorder = analyticsRecorder
        self.interactor = interactor
        self.routingInteractor = routingInteractor
        self.loader = loader
        self.alert = alert

        titleContent = .init(
            text: LocalizationIDs.title,
            font: .main(.semibold, 20.0),
            color: .textFieldText,
            alignment: .center,
            accessibility: .id(AccessibilityIDs.titleLabel)
        )
        descriptionContent = .init(
            text: "\(LocalizationIDs.Description.thisWillRemove) \(currency.name) \(LocalizationIDs.Description.buyOrder)",
            font: .main(.medium, 14.0),
            color: .textFieldText,
            alignment: .center,
            accessibility: .id(AccessibilityIDs.descriptionLabel)
        )

        noButtonViewModel = .cancel(
            with: LocalizationConstants.no,
            accessibilityId: AccessibilityIDs.noButton
        )
        yesButtonViewModel = .primary(
            with: LocalizationConstants.yes,
            accessibilityId: AccessibilityIDs.yesButton
        )

        noButtonViewModel.tapRelay
            .bindAndCatch(weak: self) { (self) in
                self.analyticsRecorder.record(event: AnalyticsEvent.sbCancelOrderGoBack)
                self.routingInteractor.previousRelay.accept(())
            }
            .disposed(by: disposeBag)

        setupCancellationBinding()
    }

    private func setupCancellationBinding() {
        let cancellationResult = yesButtonViewModel
            .tapRelay
            .show(loader: loader, style: .circle)
            .flatMap(weak: self) { (self, _) in
                self.interactor.cancel()
            }
            .mapToResult()
            .hide(loader: loader)
            .share(replay: 1)

        cancellationResult
            .filter(\.isSuccess)
            .mapToVoid()
            .bindAndCatch(weak: self) { (self) in
                self.analyticsRecorder.record(event: AnalyticsEvent.sbCancelOrderConfirmed)
                self.routingInteractor.nextRelay.accept(())
            }
            .disposed(by: disposeBag)

        cancellationResult
            .filter(\.isFailure)
            .mapToVoid()
            .bindAndCatch(weak: self) { (self) in
                self.cancellationDidFail()
            }
            .disposed(by: disposeBag)
    }

    private func cancellationDidFail() {
        alert.error(in: nil) { [dismissalRelay] in
            dismissalRelay.accept(())
        }
        analyticsRecorder.record(event: AnalyticsEvent.sbCancelOrderError)
    }

    func viewDidLoad() {
        analyticsRecorder.record(event: AnalyticsEvent.sbCancelOrderPrompt)
    }
}
