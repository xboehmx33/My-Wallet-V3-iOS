// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit
import UIKit

public protocol Buildable: AnyObject {

    var stateService: StateServiceAPI { get }

    func fundsTransferDetailsViewController() -> Single<UIViewController>
    func fundsTransferDetailsViewController(for fiatCurrency: FiatCurrency, isOriginDeposit: Bool) -> UIViewController
}

public final class Builder: Buildable {

    public let stateService: StateServiceAPI
    private let disposeBag = DisposeBag()

    private let fiatCurrencyService: FiatCurrencyServiceAPI
    private let analytics: AnalyticsEventRecorderAPI

    public init(
        fiatCurrencyService: FiatCurrencyServiceAPI = resolve(),
        stateService: StateServiceAPI,
        analytics: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.fiatCurrencyService = fiatCurrencyService
        self.stateService = stateService
        self.analytics = analytics
    }

    /// Generates and returns the `DetailsScreenViewController` for funds transfer
    /// The screen matches the wallet's currency
    /// - Returns: `Single<UIViewController>`
    public func fundsTransferDetailsViewController() -> Single<UIViewController> {
        fiatCurrencyService.displayCurrency
            .asSingle()
            .map(weak: self) { (self, fiatCurrency) in
                self.fundsTransferDetailsViewController(for: fiatCurrency, isOriginDeposit: false)
            }
    }

    /// Generates and returns the `DetailsScreenViewController` for funds transfer
    /// - Parameter fiatCurrency: The fiat currency for which the transfer details will be retrieved
    /// - Returns: A `DetailsScreenViewController` that shows the funds transfer details
    public func fundsTransferDetailsViewController(
        for fiatCurrency: FiatCurrency,
        isOriginDeposit: Bool
    ) -> UIViewController {
        let interactor = InteractiveFundsTransferDetailsInteractor(
            fiatCurrency: fiatCurrency
        )

        let navigationController = UINavigationController()

        let webViewRouter = WebViewRouter(
            topMostViewControllerProvider: navigationController
        )

        let presenter = FundsTransferDetailScreenPresenter(
            webViewRouter: webViewRouter,
            analyticsRecorder: analytics,
            interactor: interactor,
            isOriginDeposit: isOriginDeposit
        )
        presenter.backRelay
            .bind(to: stateService.previousRelay)
            .disposed(by: disposeBag)

        let viewController = DetailsScreenViewController(presenter: presenter)
        navigationController.viewControllers = [viewController]
        return navigationController
    }
}
