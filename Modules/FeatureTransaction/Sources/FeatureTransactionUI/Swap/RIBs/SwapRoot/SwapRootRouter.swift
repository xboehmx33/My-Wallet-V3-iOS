// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import FeatureKYCDomain
import FeatureKYCUI
import PlatformKit
import PlatformUIKit
import RIBs

public struct SwapTrendingPair {
    public let sourceAccount: CryptoAccount
    public let destinationAccount: CryptoAccount
    public let enabled: Bool
}

public protocol SwapRootRouting: ViewableRouting {
    /// Bootstrap determines if the user
    /// should see KYC or Swap.
    func routeToSwapBootstrap()

    /// Landing shows trending pairs
    func routeToSwapLanding()
    func routeToSwapTiers(model: KYCTiersPageModel, present: Bool)
    func routeToKYC()
    func routeToSwap(with pair: SwapTrendingPair?)
    func dismissTransactionFlow()
}

final class SwapRootRouter: ViewableRouter<SwapRootInteractor, SwapRootViewControllable>, SwapRootRouting {

    private var transactionFlowRouting: TransactionFlowRouting? {
        children
            .first(where: { $0 is TransactionFlowRouting })
            .map { child -> TransactionFlowRouting in
                child as! TransactionFlowRouting
            }
    }

    private weak var bootstrap: SwapBootstrapRouting?

    func routeToSwapBootstrap() {
        let router = SwapBootstrapBuilder().build(withListener: interactor)
        let viewControllable = router.viewControllable
        bootstrap = router
        attachChild(router)
        viewController.replaceRoot(viewController: viewControllable)
    }

    func routeToSwapLanding() {
        if let child = bootstrap {
            detachChild(child)
            bootstrap = nil
        }
        let router = SwapLandingBuilder().build(withListener: interactor)
        let viewControllable = router.viewControllable
        attachChild(router)
        viewController.replaceRoot(viewController: viewControllable, animated: false)
    }

    func routeToSwapTiers(model: KYCTiersPageModel, present: Bool) {
        let controller = KYCTiersViewController(pageModel: model, parentFlow: .swap)
        if present {
            let nav = UINavigationController(rootViewController: controller)
            viewController.present(viewController: nav)
        } else {
            viewController.replaceRoot(viewController: controller, animated: false)
        }
    }

    func routeToKYC() {
        let presenter = SwapKYCPresenter()
        let vc = DetailsScreenViewController(presenter: presenter)
        viewController.replaceRoot(viewController: vc, animated: false)
    }

    func routeToSwap(with pair: SwapTrendingPair?) {
        dismissTransactionFlow()
        precondition(transactionFlowRouting == nil, "There should be no TransactionFlowRouting child here.")
        let builder = TransactionFlowBuilder()
        let router = builder.build(
            withListener: interactor,
            action: .swap,
            sourceAccount: pair?.sourceAccount,
            target: pair?.destinationAccount
        )
        let viewControllable = router.viewControllable
        attachChild(router)
        viewController.present(viewController: viewControllable)
    }

    func dismissTransactionFlow() {
        if let transationFlowRouting = transactionFlowRouting {
            detachChild(transationFlowRouting)
        }
    }
}
