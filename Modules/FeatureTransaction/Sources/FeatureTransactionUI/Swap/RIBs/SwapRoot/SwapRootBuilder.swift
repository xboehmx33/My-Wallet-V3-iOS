// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit
import PlatformUIKit
import RIBs

// MARK: - Builder

public protocol SwapRootBuildable {
    func build() -> SwapRootRouting
}

public final class SwapRootBuilder: SwapRootBuildable {

    public init() {}

    public func build() -> SwapRootRouting {
        let viewController = SwapRootViewController()
        let interactor = SwapRootInteractor()

        viewController.listener = interactor
        let router = SwapRootRouter(
            interactor: interactor,
            viewController: viewController
        )
        interactor.router = router
        return router
    }
}
