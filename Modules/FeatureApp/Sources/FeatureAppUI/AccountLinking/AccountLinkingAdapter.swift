// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureSettingsUI
import FeatureTransactionUI
import PlatformKit
import UIKit

struct AccountLinkingFlowPresenter: AccountLinkingFlowPresenterAPI {

    let base: PaymentMethodLinkerAPI = resolve()

    func presentAccountLinkingFlow(
        from presenter: UIViewController,
        filter: @escaping (PaymentMethodType) -> Bool,
        completion: @escaping (AccountLinkingFlowPresenterCompletion) -> Void
    ) {
        base.presentAccountLinkingFlow(from: presenter, filter: filter) { result in
            switch result {
            case .abandoned:
                completion(.dismiss)
            case .completed(let method):
                completion(.select(method))
            }
        }
    }
}
