// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ToolKit
import UIKit

/// A little helper for `SingleChildViewController<Either<Left, Right>>`
public typealias EitherViewController<
    Left: ViewControllerProvider,
    Right: ViewControllerProvider
> = SingleChildViewController<Either<Left, Right>>

/// Allowing direct access to left or right viewController in `Either`
extension Either: ViewControllerProvider where A: ViewControllerProvider, B: ViewControllerProvider {
    public var viewController: UIViewController {
        switch self {
        case .left(let a):
            return a.viewController
        case .right(let b):
            return b.viewController
        }
    }
}
