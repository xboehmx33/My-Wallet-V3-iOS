// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import Foundation
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit
import UIKit

protocol BankWireLinkerAPI {
    func present(from presenter: UIViewController, completion: @escaping () -> Void)
}

final class BankWireLinker: BankWireLinkerAPI {

    private let fiatCurrencyService: FiatCurrencyServiceAPI
    private let analytics: AnalyticsEventRecorderAPI
    private var disposeBag: DisposeBag!

    init(
        fiatCurrencyService: FiatCurrencyServiceAPI = resolve(),
        analytics: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.fiatCurrencyService = fiatCurrencyService
        self.analytics = analytics
    }

    func present(from presenter: UIViewController, completion: @escaping () -> Void) {
        disposeBag = DisposeBag() // avoid memory leak when binding completion
        fundsTransferDetailsViewController(completion: completion)
            .subscribe(on: MainScheduler.instance)
            .subscribe { viewController in
                presenter.present(viewController, animated: true)
            } onFailure: { error in
                Logger.shared.error(error)
            }
            .disposed(by: disposeBag)
    }

    /// Generates and returns the `DetailsScreenViewController` for funds transfer
    /// The screen matches the wallet's currency
    /// - Returns: `Single<UIViewController>`
    private func fundsTransferDetailsViewController(completion: @escaping () -> Void) -> Single<UIViewController> {
        fiatCurrencyService.displayCurrency
            .asSingle()
            .map(weak: self) { (self, fiatCurrency) in
                self.fundsTransferDetailsViewController(
                    for: fiatCurrency,
                    isOriginDeposit: false,
                    completion: completion
                )
            }
    }

    /// Generates and returns the `DetailsScreenViewController` for funds transfer
    /// - Parameter fiatCurrency: The fiat currency for which the transfer details will be retrieved
    /// - Returns: A `DetailsScreenViewController` that shows the funds transfer details
    private func fundsTransferDetailsViewController(
        for fiatCurrency: FiatCurrency,
        isOriginDeposit: Bool,
        completion: @escaping () -> Void
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
            .bind(onNext: completion)
            .disposed(by: disposeBag)

        let viewController = DetailsScreenViewController(presenter: presenter)
        navigationController.viewControllers = [viewController]
        return navigationController
    }
}
