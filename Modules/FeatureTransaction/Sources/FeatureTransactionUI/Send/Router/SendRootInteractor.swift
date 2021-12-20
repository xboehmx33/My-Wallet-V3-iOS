// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import PlatformKit
import PlatformUIKit
import RIBs
import RxSwift
import ToolKit

public protocol SendRootRouting: ViewableRouting {
    /// Landing shows the wallets that the user
    /// can send from.
    func routeToSendLanding()
    func routeToSendLanding(navigationBarHidden: Bool)
    func routeToSend(sourceAccount: BlockchainAccount)
    func routeToSend(sourceAccount: BlockchainAccount, destination: TransactionTarget)
    func dismissTransactionFlow()
}

public protocol SendRootListener: ViewListener {}

final class SendRootInteractor: Interactor, SendRootInteractable, SendRootListener {

    weak var router: SendRootRouting?
    weak var listener: SendRootListener?

    private let analyticsRecorder: AnalyticsEventRecorderAPI

    init(analyticsRecorder: AnalyticsEventRecorderAPI = resolve()) {
        self.analyticsRecorder = analyticsRecorder
        super.init()
    }

    func presentKYCFlowIfNeeded(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        unimplemented()
    }

    func dismissTransactionFlow() {
        router?.dismissTransactionFlow()
    }
}
