// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import PlatformUIKit
import RIBs
import RxSwift
import ToolKit

protocol SendRootViewControllable: ViewControllable {
    func replaceRoot(viewController: ViewControllable?)
    func replaceRoot(viewController: ViewControllable?, animated: Bool)
    func present(viewController: ViewControllable?)
    func present(viewController: ViewControllable?, animated: Bool)
}

extension SendRootViewControllable {
    func replaceRoot(viewController: ViewControllable?) {
        replaceRoot(viewController: viewController, animated: true)
    }

    func present(viewController: ViewControllable?) {
        present(viewController: viewController, animated: true)
    }
}

final class SendRootViewController: UINavigationController, SendRootViewControllable {

    // MARK: - Public

    weak var listener: SendRootListener?

    // MARK: - Private Properties

    private let topMostViewControllerProvider: TopMostViewControllerProviding
    private var hideNavigationBar: Bool = false
    private var hideNavigationBarSubscription: AnyCancellable?

    @LazyInject var featureFlagsService: FeatureFlagsServiceAPI

    // MARK: - Init

    init(topMostViewControllerProvider: TopMostViewControllerProviding = resolve()) {
        self.topMostViewControllerProvider = topMostViewControllerProvider
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
        hideNavigationBarSubscription = featureFlagsService.isEnabled(.remote(.redesign))
            .assign(to: \.hideNavigationBar, on: self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setNavigationBarHidden(hideNavigationBar, animated: false)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    // MARK: - Public Functions (SendRootViewControllable)

    func replaceRoot(viewController: ViewControllable?, animated: Bool) {
        guard let viewController = viewController else {
            return
        }
        setViewControllers([viewController.uiviewController], animated: animated)
    }

    func present(viewController: ViewControllable?, animated: Bool) {
        guard let viewController = viewController else {
            return
        }
        topMostViewControllerProvider.topMostViewController?
            .present(viewController.uiviewController, animated: animated)
    }
}
