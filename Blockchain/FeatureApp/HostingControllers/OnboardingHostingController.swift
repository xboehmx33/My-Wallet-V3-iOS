// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComponentLibrary
import ComposableArchitecture
import DIKit
import FeatureAppUI
import FeatureAuthenticationUI
import PlatformUIKit
import SwiftUI
import ToolKit
import UIKit

/// Acts as a container for Pin screen and Login screen
final class OnboardingHostingController: UIViewController {

    let store: Store<Onboarding.State, Onboarding.Action>
    let viewStore: ViewStore<Onboarding.State, Onboarding.Action>

    private let alertViewPresenter: AlertViewPresenterAPI
    private let webViewService: WebViewServiceAPI

    private let featureFlagService: FeatureFlagsServiceAPI
    private var currentController: UIViewController?
    private var cancellables: Set<AnyCancellable> = []

    /// This is assigned when the recover funds option is selected on the WelcomeScreen
    private var recoverWalletNavigationController: UINavigationController?

    init(
        store: Store<Onboarding.State, Onboarding.Action>,
        alertViewPresenter: AlertViewPresenterAPI = resolve(),
        webViewService: WebViewServiceAPI = resolve(),
        featureFlagService: FeatureFlagsServiceAPI = DIKit.resolve()
    ) {
        self.store = store
        viewStore = ViewStore(store)
        self.alertViewPresenter = alertViewPresenter
        self.webViewService = webViewService
        self.featureFlagService = featureFlagService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewStore.publisher
            .displayAlert
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] alert in
                guard let self = self else { return }
                self.showAlert(type: alert)
            }
            .store(in: &cancellables)

        store
            .scope(state: \.welcomeState, action: Onboarding.Action.welcomeScreen)
            .ifLet(then: { [weak self] authStore in
                guard let self = self else { return }
                let hostingController = UIHostingController(rootView: self.makeWelcomeView(store: authStore))
                self.transitionFromCurrentController(to: hostingController)
                hostingController.view.constraint(edgesTo: self.view)
                self.currentController = hostingController
            })
            .store(in: &cancellables)

        store
            .scope(state: \.pinState, action: Onboarding.Action.pin)
            .ifLet(then: { [weak self] pinStore in
                guard let self = self else { return }
                let pinHostingController = PinHostingController(store: pinStore)
                // TODO: Dismiss the alert in the respective presenting view (credentials view). This is a temporary solution until the alert state issue is resolved
                if self.topMostViewController != self.currentController {
                    self.topMostViewController?.dismiss(animated: true, completion: nil)
                }
                self.transitionFromCurrentController(to: pinHostingController)
                self.currentController = pinHostingController
            })
            .store(in: &cancellables)

        store
            .scope(state: \.passwordScreen, action: Onboarding.Action.passwordScreen)
            .ifLet(then: { [weak self] _ in
                guard let self = self else { return }
                let walletFetcher: (String) -> Void = { [weak self] password in
                    self?.viewStore.send(.passwordScreen(.authenticate(password)))
                }
                let forgetWalletRouting: () -> Void = { [weak self] in
                    self?.viewStore.send(.passwordScreen(.forgetWallet))
                }
                let interactor = PasswordRequiredScreenInteractor(walletFetcher: walletFetcher)
                let presenter = PasswordRequiredScreenPresenter(
                    interactor: interactor,
                    forgetWalletRouting: forgetWalletRouting
                )
                let viewController = PasswordRequiredViewController(presenter: presenter)
                let navigationController = UINavigationController(rootViewController: viewController)

                self.transitionFromCurrentController(to: navigationController)
                self.currentController = navigationController
            })
            .store(in: &cancellables)

        store
            .scope(state: \.walletUpgradeState, action: Onboarding.Action.walletUpgrade)
            .ifLet(then: { [weak self] _ in
                guard let self = self else { return }
                let walletUpgradeController = self.setupWalletUpgrade {
                    self.viewStore.send(.walletUpgrade(.completed))
                }
                self.transitionFromCurrentController(to: walletUpgradeController)
                self.currentController = walletUpgradeController
            })
            .store(in: &cancellables)
    }

    // MARK: Private

    @ViewBuilder
    private func makeWelcomeView(store: Store<WelcomeState, WelcomeAction>) -> some View {
        PrimaryNavigationView {
            TourViewAdapter(store: store, featureFlagService: self.featureFlagService)
                .primaryNavigation()
                .navigationBarHidden(true)
        }
    }

    /// Transition from the current controller, if any to the specified controller.
    private func transitionFromCurrentController(to controller: UIViewController) {
        if let currentController = currentController {
            transition(
                from: currentController,
                to: controller,
                animate: true
            )
        } else {
            add(child: controller)
        }
    }

    // MARK: Wallet Upgrade

    // Provides the view controller that displays the wallet upgrade
    private func setupWalletUpgrade(completion: @escaping () -> Void) -> WalletUpgradeViewController {
        let interactor = WalletUpgradeInteractor(completion: completion)
        let presenter = WalletUpgradePresenter(interactor: interactor)
        return WalletUpgradeViewController(presenter: presenter)
    }

    // MARK: Create Wallet

    private func presentCreateWallet() {
        let interactor = CreateWalletInteractor()
        let presenter = RegisterWalletScreenPresenter(
            interactor: interactor,
            navBarStyle: .darkContent(),
            leadingButton: .none,
            trailingButton: .close
        )
        let navigationController = UINavigationController()
        let cancellable = presenter.webViewLaunchRelay
            .asObservable()
            .asPublisher()
            .ignoreFailure()
            .sink { [weak webViewService] url in
                webViewService?.openSafari(url: url, from: navigationController)
            }
        let dismissHandler = { [weak viewStore] in
            viewStore?.send(.createAccountScreenClosed)
            cancellable.cancel()
        }
        let viewController = RegisterWalletViewController(presenter: presenter, dismissHandler: dismissHandler)
        // disallow swipe down to dismiss
        viewController.isModalInPresentation = true
        navigationController.setViewControllers([viewController], animated: false)
        present(navigationController, animated: true, completion: nil)
    }

    // MARK: Alerts

    private func showAlert(type: Onboarding.Alert) {
        switch type {
        case .proceedToLoggedIn(.coincore(let error)):
            let content = AlertViewContent(
                title: LocalizationConstants.Errors.error,
                message: LocalizationConstants.Errors.genericError + " " + error.localizedDescription
            )
            alertViewPresenter.notify(content: content, in: self)
        case .proceedToLoggedIn(.erc20Service(let error)):
            let content = AlertViewContent(
                title: LocalizationConstants.Errors.error,
                message: LocalizationConstants.Errors.genericError + " " + error.localizedDescription
            )
            alertViewPresenter.notify(content: content, in: self)
        case .walletAuthentication(let error) where error.code == .failedToLoadWallet:
            handleFailedToLoadWalletAlert()
        case .walletAuthentication(let error) where error.code == .noInternet:
            let content = AlertViewContent(
                title: LocalizationConstants.Errors.error,
                message: LocalizationConstants.Errors.noInternetConnection
            )
            alertViewPresenter.notify(content: content, in: self)
        case .walletAuthentication(let error):
            if let description = error.description {
                let content = AlertViewContent(
                    title: LocalizationConstants.Errors.error,
                    message: description
                )
                alertViewPresenter.notify(content: content, in: self)
            }
        case .walletCreation(let error):
            let content = AlertViewContent(
                title: LocalizationConstants.Errors.error,
                message: error.localizedDescription
            )
            alertViewPresenter.notify(content: content, in: self)
        case .walletRecovery(let error):
            let content = AlertViewContent(
                title: LocalizationConstants.Errors.error,
                message: error.localizedDescription
            )
            alertViewPresenter.notify(content: content, in: self)
        }
    }
}

extension OnboardingHostingController {
    // TODO: We should revisit this
    private func handleFailedToLoadWalletAlert() {
        let alertController = UIAlertController(
            title: LocalizationConstants.Authentication.failedToLoadWallet,
            message: LocalizationConstants.Authentication.failedToLoadWalletDetail,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: LocalizationConstants.Authentication.forgetWallet, style: .default) { [weak self] _ in

                let forgetWalletAlert = UIAlertController(
                    title: LocalizationConstants.Errors.warning,
                    message: LocalizationConstants.Authentication.forgetWalletDetail,
                    preferredStyle: .alert
                )
                forgetWalletAlert.addAction(
                    UIAlertAction(title: LocalizationConstants.cancel, style: .cancel) { [weak self] _ in
                        self?.handleFailedToLoadWalletAlert()
                    }
                )
                forgetWalletAlert.addAction(
                    UIAlertAction(
                        title: LocalizationConstants.Authentication.forgetWallet,
                        style: .default
                    ) { [weak self] _ in
                        self?.viewStore.send(.forgetWallet)
                    }
                )
                self?.present(forgetWalletAlert, animated: true)
            }
        )
        alertController.addAction(
            UIAlertAction(title: LocalizationConstants.Authentication.forgetWallet, style: .default) { _ in
                UIApplication.shared.suspendApp()
            }
        )
        present(alertController, animated: true)
    }
}

extension OnboardingHostingController {
    override public var childForStatusBarStyle: UIViewController? { currentController }
    override public var childForStatusBarHidden: UIViewController? { currentController }
    override public var childForHomeIndicatorAutoHidden: UIViewController? { currentController }
    override public var childForScreenEdgesDeferringSystemGestures: UIViewController? { currentController }
    override public var childViewControllerForPointerLock: UIViewController? { currentController }
}
