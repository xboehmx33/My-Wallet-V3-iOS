// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit
import Stripe
import UIKit

public protocol StripeUIClientAPI {
    func confirmPayment(
        _ data: PartnerAuthorizationData,
        with presenter: CardAuthorizationScreenPresenter
    )
}

class StripeUIClient: NSObject, StripeUIClientAPI {
    private static let returnURL = "blockchain://stripe/return"
    private weak var presentingVC: UIViewController?

    func confirmPayment(
        _ data: PartnerAuthorizationData,
        with presenter: CardAuthorizationScreenPresenter
    ) {
        guard case .required(let params) = data.state,
              params.cardAcquirer == .stripe,
              let publishableApiKey = params.publishableApiKey,
              let clientSecret = params.clientSecret,
              let presentingVC = UIApplication.shared.topMostViewController
        else {
            presenter.redirect()
            return
        }

        var configuration = PaymentSheet.Configuration()
        configuration.apiClient = STPAPIClient(publishableKey: publishableApiKey)
        configuration.allowsDelayedPaymentMethods = true

        self.presentingVC = presentingVC

        let handler = STPPaymentHandler.shared()
        handler.apiClient = STPAPIClient(publishableKey: publishableApiKey)
        handler.confirmPayment(STPPaymentIntentParams(clientSecret: clientSecret), with: self) { _, _, _ in
            presenter.redirect()
        }
    }
}

extension StripeUIClient: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        presentingVC!
    }
}
