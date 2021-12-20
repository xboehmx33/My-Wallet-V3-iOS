// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import DIKit
import FeatureAppUI
import FeatureAuthenticationDomain
import FeatureAuthenticationUI
import PlatformUIKit
import SwiftUI
import ToolKit
import UIKit

protocol LoggedInViewController: UIViewController, LoggedInBridge {
    init(store: Store<LoggedIn.State, LoggedIn.Action>)
    func clear()
}

extension LoggedInHostingController: LoggedInViewController {}
extension RootViewController: LoggedInViewController {}

/// Acts as the main controller for onboarding and logged in states
final class AppHostingController: UIViewController {
    let store: Store<CoreAppState, CoreAppAction>
    let viewStore: ViewStore<CoreAppState, CoreAppAction>

    @LazyInject var alertViewPresenter: AlertViewPresenterAPI

    private var onboardingController: OnboardingHostingController?
    private var loggedInController: LoggedInViewController?
    private var loggedInDependencyBridge: LoggedInDependencyBridgeAPI
    private var featureFlagsService: FeatureFlagsServiceAPI

    private var cancellables: Set<AnyCancellable> = []

    init(
        store: Store<CoreAppState, CoreAppAction>,
        loggedInDependencyBridge: LoggedInDependencyBridgeAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        self.store = store
        viewStore = ViewStore(store)
        self.loggedInDependencyBridge = loggedInDependencyBridge
        self.featureFlagsService = featureFlagsService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.0431372549, green: 0.1019607843, blue: 0.2784313725, alpha: 1)

        viewStore
            .publisher
            .alertContent
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] content in
                guard let self = self else { return }
                self.showAlert(with: content)
            }
            .store(in: &cancellables)

        store
            .scope(state: \.onboarding, action: CoreAppAction.onboarding)
            .ifLet(then: { [weak self] onboardingStore in
                guard let self = self else { return }
                let onboardingController = OnboardingHostingController(store: onboardingStore)
                if let loggedInController = self.loggedInController {
                    self.transition(
                        from: loggedInController,
                        to: onboardingController,
                        animate: true
                    )
                } else {
                    self.add(child: onboardingController)
                }
                self.onboardingController = onboardingController
                self.loggedInDependencyBridge.unregister()
                self.loggedInController?.clear()
                self.loggedInController = nil
            })
            .store(in: &cancellables)

        store
            .scope(state: \.loggedIn, action: CoreAppAction.loggedIn)
            .ifLet(then: { [weak self] store in
                guard let self = self else { return }

                func load(_ loggedInController: LoggedInViewController) {
                    // this is important, register the controller as a bridge
                    // for many places throughout the app
                    self.loggedInDependencyBridge.register(bridge: loggedInController)
                    loggedInController.view.frame = self.view.bounds
                    if let onboardingController = self.onboardingController {
                        self.transition(
                            from: onboardingController,
                            to: loggedInController,
                            animate: true
                        )
                    } else {
                        self.add(child: loggedInController)
                    }
                    self.loggedInController = loggedInController
                    self.onboardingController = nil
                }

                self.featureFlagsService.isEnabled(.remote(.redesign))
                    .sink { isEnabled in
                        if isEnabled {
                            load(RootViewController(store: store))
                        } else {
                            load(LoggedInHostingController(store: store))
                        }
                    }
                    .store(in: &self.cancellables)
            })
            .store(in: &cancellables)

        store
            .scope(state: \.deviceAuthorization, action: CoreAppAction.authorizeDevice)
            .ifLet(then: { [weak self] authorizeDeviceScope in
                guard let self = self else { return }
                let nav = AuthorizeDeviceViewController(
                    store: authorizeDeviceScope,
                    viewDismissed: { [weak self] in
                        self?.viewStore.send(.deviceAuthorizationFinished)
                    }
                )
                self.topMostViewController?.present(nav, animated: true, completion: nil)
            })
            .store(in: &cancellables)
    }

    private func showAlert(with content: AlertViewContent) {
        alertViewPresenter.notify(content: content, in: self)
    }
}

extension AppHostingController {

    private var currentController: UIViewController? { loggedInController ?? onboardingController }

    override public var childForStatusBarStyle: UIViewController? { currentController }
    override public var childForStatusBarHidden: UIViewController? { currentController }
    override public var childForHomeIndicatorAutoHidden: UIViewController? { currentController }
    override public var childForScreenEdgesDeferringSystemGestures: UIViewController? { currentController }
    override public var childViewControllerForPointerLock: UIViewController? { currentController }
}
