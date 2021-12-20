// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import FeatureTransactionDomain
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxSwift

final class ReceiveRouter: ReceiveRouterAPI {
    private typealias LocalizedString = LocalizationConstants.Receive

    private let navigationRouter: NavigationRouterAPI

    private let webViewService: WebViewServiceAPI

    private let analyticsRecorder: AnalyticsEventRecorderAPI

    private let disposeBag = DisposeBag()

    init(
        navigationRouter: NavigationRouterAPI = NavigationRouter(),
        webViewService: WebViewServiceAPI = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve()
    ) {
        self.navigationRouter = navigationRouter
        self.webViewService = webViewService
        self.analyticsRecorder = analyticsRecorder
    }

    func presentReceiveScreen(for account: BlockchainAccount) {
        guard let account = account as? SingleAccount else {
            return
        }
        let interactor = ReceiveScreenInteractor(account: account)
        let presenter = ReceiveScreenPresenter(interactor: interactor)
        let receive = ReceiveScreenViewController(presenter: presenter)
        let nav = UINavigationController(rootViewController: receive)
        presenter.webViewLaunchRelay
            .bind { [weak self] url in
                self?.webViewService.openSafari(url: url, from: receive)
            }
            .disposed(by: disposeBag)
        navigationRouter.present(viewController: nav)
        analyticsRecorder.record(event: AnalyticsEvents.New.Send.sendReceiveViewed(type: .receive))
    }

    func presentKYCScreen() {
        let presenter = ReceiveKYCPresenter()
        let viewController = DetailsScreenViewController(presenter: presenter)
        navigationRouter.present(viewController: viewController)
    }

    func shareDetails(for metadata: CryptoAssetQRMetadata, currencyType: CurrencyType) {
        let displayCode = currencyType.displayCode
        let prefix = String(format: LocalizedString.Text.pleaseSendXTo, displayCode)
        let message = "\(prefix) \(metadata.absoluteString)"
        let subject = String(format: LocalizedString.Text.xPaymentRequest, displayCode)
        let activityViewController = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [.assignToContact, .addToReadingList, .postToFacebook]
        activityViewController.setValue(subject, forKey: "subject")
        navigationRouter.present(viewController: activityViewController)
    }
}
