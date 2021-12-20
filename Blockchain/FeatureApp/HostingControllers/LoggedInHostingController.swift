// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import DIKit
import FeatureAppUI
import FeatureAuthenticationDomain
import FeatureDashboardUI
import FeatureInterestUI
import FeatureOnboardingUI
import FeatureSettingsUI
import FeatureWalletConnectDomain
import MoneyKit
import PlatformKit
import PlatformUIKit
import ToolKit

/// Acts as a container for the Home screen
final class LoggedInHostingController: UIViewController, LoggedInBridge {

    let store: Store<LoggedIn.State, LoggedIn.Action>
    let viewStore: ViewStore<LoggedIn.State, LoggedIn.Action>
    var cancellables: Set<AnyCancellable> = []

    // MARK: - The controllers

    var sideMenuViewController: SideMenuViewController?
    var tabControllerManager: TabControllerManager?
    var slidingViewController: ECSlidingViewController?

    weak var accountsAndAddressesNavigationController: AccountsAndAddressesNavigationController?

    @LazyInject var featureFlagService: FeatureFlagsServiceAPI
    @LazyInject var customerSupportChatRouter: CustomerSupportChatRouterAPI
    @LazyInject var alertViewPresenter: AlertViewPresenterAPI
    @LazyInject var secureChannelRouter: SecureChannelRouting
    @LazyInject var coincore: CoincoreAPI

    @Inject var airdropRouter: AirdropRouterAPI

    let walletConnectService: WalletConnectServiceAPI
    private let walletConnectRouter: WalletConnectRouterAPI
    private let onboardingRouter: FeatureOnboardingUI.OnboardingRouterAPI
    private let kycRouter: PlatformUIKit.KYCRouting

    var tiersService: KYCTiersServiceAPI
    var simpleBuyEligiblityService: EligibilityServiceAPI
    var settingsRouterAPI: SettingsRouterAPI?
    var buyRouter: PlatformUIKit.RouterAPI?
    var backupRouter: FeatureDashboardUI.BackupRouterAPI?
    var pinRouter: PinRouter?

    @LazyInject var transactionsAdapter: TransactionsAdapterAPI
    @LazyInject var nabuAuthenticationErrorReceiver: NabuAuthenticationErrorReceiverAPI

    convenience init(store: Store<LoggedIn.State, LoggedIn.Action>) {
        self.init(
            store: store,
            onboardingRouter: resolve(),
            tiersService: resolve(),
            kycRouter: resolve(),
            eligibilityService: resolve()
        )
    }

    init(
        store: Store<LoggedIn.State, LoggedIn.Action>,
        onboardingRouter: FeatureOnboardingUI.OnboardingRouterAPI = resolve(),
        tiersService: KYCTiersServiceAPI = resolve(),
        kycRouter: KYCRouting = resolve(),
        eligibilityService: EligibilityServiceAPI = resolve(),
        walletConnectService: WalletConnectServiceAPI = resolve(),
        walletConnectRouter: WalletConnectRouterAPI = resolve()
    ) {
        self.kycRouter = kycRouter
        self.store = store
        self.tiersService = tiersService
        simpleBuyEligiblityService = eligibilityService
        viewStore = ViewStore(store)
        self.onboardingRouter = onboardingRouter
        self.walletConnectRouter = walletConnectRouter
        self.walletConnectService = walletConnectService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let sideMenu = sideMenuProvider()
        let tabController = tabControllerProvider()
        let slidingViewController = slidingControllerProvider(
            sideMenuController: sideMenu,
            tabController: tabController
        )
        add(child: slidingViewController)
        self.slidingViewController = slidingViewController
        sideMenuViewController = sideMenu
        tabControllerManager = tabController

        sideMenuViewController?.tabControllerManager = tabControllerManager
        sideMenuViewController?.slidingViewController = slidingViewController

        setupBindings()

        nabuAuthenticationErrorReceiver
            .userAlreadyRestored
            .receive(on: RunLoop.main)
            // make sure we only receive the value once so that the error is not shown more than one time
            .prefix(1)
            .sink(receiveValue: { walletIdHint in
                self.showNabuUserConflictErrorIfNeeded(walletIdHint: walletIdHint)
            })
            .store(in: &cancellables)
    }

    func clear() {
        cancellables.forEach { $0.cancel() }
        sideMenuViewController?.delegate = nil
        sideMenuViewController?.createGestureRecognizers = nil
        sideMenuViewController = nil
        tabControllerManager = nil
        slidingViewController?.remove()
        slidingViewController = nil
    }

    // MARK: Private

    private func setupBindings() {
        viewStore.publisher
            .reloadAfterMultiAddressResponse
            .filter { $0 }
            .sink { [weak self] _ in
                self?.reloadAfterMultiAddressResponse()
            }
            .store(in: &cancellables)

        viewStore.publisher
            .reloadAfterSymbolChanged
            .filter { $0 }
            .sink { [weak self] _ in
                self?.accountsAndAddressesNavigationController?.reload()
                self?.sideMenuViewController?.reload()
            }
            .store(in: &cancellables)

        viewStore.publisher
            .displayWalletAlertContent
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] content in
                self?.showAlert(with: content)
            }
            .store(in: &cancellables)

        viewStore.publisher
            .displaySendCryptoScreen
            .filter { $0 }
            .sink { [weak self] _ in
                self?.switchToSend()
            }
            .store(in: &cancellables)

        viewStore.publisher
            .displayOnboardingFlow
            .filter { $0 }
            .sink { [weak self] _ in
                self?.presentOnboardingFlow()
            }
            .store(in: &cancellables)

        viewStore.publisher
            .displayLegacyBuyFlow
            .filter { $0 }
            .sink { [weak self] _ in
                self?.startSimpleBuyAtLogin()
            }
            .store(in: &cancellables)
    }

    private func sideMenuProvider() -> SideMenuViewController {
        let sideMenuController = SideMenuViewController.makeFromStoryboard()
        sideMenuController.delegate = self
        sideMenuController.createGestureRecognizers = { [weak self] in
            guard let self = self else { return nil }
            return (
                UITapGestureRecognizer(
                    target: self,
                    action: #selector(Self.toggleSideMenu)
                ),
                UITapGestureRecognizer(
                    target: self,
                    action: #selector(Self.toggleSideMenu)
                )
            )
        }
        return sideMenuController
    }

    private func tabControllerProvider() -> TabControllerManager {
        TabControllerManager()
    }

    private func slidingControllerProvider(
        sideMenuController: SideMenuViewController?,
        tabController: TabControllerManager?
    ) -> ECSlidingViewController {
        let viewController = ECSlidingViewController()
        // Assign the required controllers
        viewController.underLeftViewController = sideMenuController
        viewController.topViewController = tabController?.tabViewController
        // Configure the main controller
        tabController?.tabViewController.sideMenuGesture = viewController.panGesture
        tabController?.tabViewController.loadViewIfNeeded()
        // Configure side menu controller
        sideMenuController?.peekPadding = viewController.anchorRightPeekAmount
        // Show dashboard as the default screen
        tabController?.showDashboard()
        return viewController
    }

    private func showAlert(with content: AlertViewContent) {
        alertViewPresenter.notify(content: content, in: self)
    }

    // MARK: AuthenticationCoordinating

    func enableBiometrics() {
        guard let slidingViewController = slidingViewController else {
            return
        }
        let logout = { [weak self] () -> Void in
            self?.viewStore.send(.logout)
        }
        let boxedParent = UnretainedContentBox<UIViewController>(slidingViewController.topMostViewController)
        let flow = PinRouting.Flow.enableBiometrics(parent: boxedParent, logoutRouting: logout)
        pinRouter = PinRouter(flow: flow) { [weak self] input in
            guard let password = input.password else { return }
            self?.viewStore.send(.wallet(.authenticateForBiometrics(password: password)))
            self?.pinRouter = nil
        }
        pinRouter?.execute()
    }

    func changePin() {
        guard let slidingViewController = slidingViewController else {
            return
        }
        let logout = { [weak self] () -> Void in
            self?.viewStore.send(.logout)
        }
        let boxedParent = UnretainedContentBox<UIViewController>(slidingViewController.topMostViewController)
        let flow = PinRouting.Flow.change(parent: boxedParent, logoutRouting: logout)
        pinRouter = PinRouter(flow: flow) { [weak self] _ in
            self?.pinRouter = nil
        }
        pinRouter?.execute()
    }

    // MARK: Email Verification

    private func presentOnboardingFlow() {
        guard let viewController = slidingViewController?.topMostViewController else {
            fatalError("🔴 Could not present Email Verification Flow: topMostViewController is nil!")
        }
        onboardingRouter.presentOnboarding(from: viewController)
            .sink { onboardingResult in
                Logger.shared.debug("[AuthenticationCoordinator] Onboarding completed with result: \(onboardingResult)")
                viewController.dismiss(animated: true, completion: nil)
            }
            .store(in: &cancellables)
    }

    private func dismissTopMost(
        weak object: LoggedInHostingController,
        _ selector: @escaping (LoggedInHostingController) -> Void
    ) {
        guard let viewController = topMostViewController else {
            selector(object)
            return
        }
        viewController.dismiss(animated: true, completion: {
            selector(object)
        })
    }
}

extension LoggedInHostingController: SideMenuViewControllerDelegate {
    // swiftlint:disable:next cyclomatic_complexity
    func sideMenuViewController(
        _ viewController: SideMenuViewController,
        didTapOn item: SideMenuItem
    ) {
        switch item {
        case .interest:
            handleInterest()
        case .backup:
            startBackupFlow()
        case .accountsAndAddresses:
            handleAccountsAndAddresses()
        case .settings:
            handleSettings()
        case .support:
            handleSupport()
        case .airdrops:
            handleAirdrops()
        case .logout:
            handleLogout()
        case .buy:
            handleBuyCrypto()
        case .sell:
            handleSellCrypto()
        case .exchange:
            handleExchange()
        case .secureChannel:
            handleSecureChannel()
        }
    }

    // MARK: - LoggedInReloadAPI

    func reload() {
        accountsAndAddressesNavigationController?.reload()
        sideMenuViewController?.reload()
    }
}

extension LoggedInHostingController {
    @objc // needed as we use this for gesture recognizers
    func toggleSideMenu() {
        // If the sideMenu is not shown, show it
        if slidingViewController?.currentTopViewPosition == .centered {
            slidingViewController?.anchorTopViewToRight(animated: true)
        } else {
            slidingViewController?.resetTopView(animated: true)
        }
    }

    func closeSideMenu() {
        guard let slidingViewController = slidingViewController else {
            return
        }
        guard slidingViewController.currentTopViewPosition != .centered else {
            return
        }
        slidingViewController.resetTopView(animated: true)
    }

    func showSettingsView() {
        let router: SettingsRouterAPI = resolve()
        settingsRouterAPI = router
        router.presentSettings()
    }

    // MARK: - TabSwapping

    func interestTransfer(into account: BlockchainAccount) {
        guard let interestAccount = account as? CryptoInterestAccount else {
            fatalError("Expected a CryptoInterestAccount")
        }
        guard let viewController = topMostViewController else {
            fatalError("Expected a UIViewController")
        }
        transactionsAdapter
            .presentTransactionFlow(
                to: .interestTransfer(interestAccount),
                from: viewController
            ) { result in
                Logger.shared.info("Interest Transfer Transaction Flow completed with result '\(result)'")
            }
    }

    func interestWithdraw(from account: BlockchainAccount) {
        guard let interestAccount = account as? CryptoInterestAccount else {
            fatalError("Expected a CryptoInterestAccount")
        }
        guard let viewController = topMostViewController else {
            fatalError("Expected a UIViewController")
        }
        transactionsAdapter
            .presentTransactionFlow(
                to: .interestWithdraw(interestAccount),
                from: viewController
            ) { result in
                Logger.shared.info("Interest Transfer Transaction Flow completed with result '\(result)'")
            }
    }

    func receive(into account: BlockchainAccount) {
        tabControllerManager?.receive(into: account)
    }

    func deposit(into account: BlockchainAccount) {
        tabControllerManager?.deposit(into: account)
    }

    func withdraw(from account: BlockchainAccount) {
        tabControllerManager?.withdraw(from: account)
    }

    func send(from account: BlockchainAccount) {
        tabControllerManager?.send(from: account)
    }

    func send(from account: BlockchainAccount, target: TransactionTarget) {
        tabControllerManager?.send(from: account, target: target)
    }

    func sign(from account: BlockchainAccount, target: TransactionTarget) {
        guard let account = account as? CryptoAccount else {
            fatalError("Expected a CryptoAccount")
        }
        guard let viewController = topMostViewController else {
            fatalError("Expected a UIViewController")
        }
        transactionsAdapter
            .presentTransactionFlow(
                to: .sign(sourceAccount: account, destination: target),
                from: viewController
            ) { result in
                Logger.shared.info("Sign Transaction Flow completed with result '\(result)'")
            }
    }

    func switchTabToDashboard() {
        tabControllerManager?.showDashboard()
    }

    func switchToSend() {
        tabControllerManager?.showSend()
    }

    func switchTabToSwap() {
        tabControllerManager?.showSwap()
    }

    func switchTabToReceive() {
        tabControllerManager?.showReceive()
    }

    func switchToActivity() {
        tabControllerManager?.showTransactions()
    }

    func switchToActivity(for currencyType: CurrencyType) {
        tabControllerManager?.showTransactions()
    }

    // MARK: - InterestAccountListHostingControllerDelegate

    func presentBuyIfNeeded(_ cryptoCurrency: CryptoCurrency) {
        dismissTopMost(weak: self) { (self) in
            self.handleBuyCrypto(currency: cryptoCurrency)
        }
    }

    func presentKYCIfNeeded() {
        /// Dismiss the Interest List View
        dismissTopMost(weak: self) { (self) in
            guard let viewController = self.topMostViewController else {
                fatalError("Expected a UIViewController")
            }
            /// Present KYC
            self.kycRouter
                .presentKYCIfNeeded(
                    from: viewController,
                    requiredTier: .tier2
                )
                .mapToResult()
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] result in
                    switch result {
                    case .success(let kycRoutingResult):
                        guard case .completed = kycRoutingResult else { return }
                        /// Upon successful KYC completion, present Interest
                        self?.handleInterest()
                    case .failure(let kycRoutingError):
                        Logger.shared.error(kycRoutingError)
                    }
                })
                .store(in: &self.cancellables)
        }
    }

    // MARK: - CashIdentityVerificationAnnouncementRouting

    func showCashIdentityVerificationScreen() {
        let presenter = CashIdentityVerificationPresenter()
        let controller = CashIdentityVerificationViewController(presenter: presenter)
        tabControllerManager?.tabViewController.showCashIdentityVerificatonController(controller)
    }

    // MARK: - InterestIdentityVerificationAnnouncementRouting

    func showInterestDashboardAnnouncementScreen(isKYCVerfied: Bool) {
        var presenter: InterestDashboardAnnouncementPresenting
        let router = InterestDashboardAnnouncementRouter(
            navigationRouter: NavigationRouter()
        )
        if isKYCVerfied {
            presenter = InterestDashboardAnnouncementScreenPresenter(
                router: router
            )
        } else {
            presenter = InterestIdentityVerificationScreenPresenter(
                router: router
            )
        }
        let controller = InterestDashboardAnnouncementViewController(presenter: presenter)
        tabControllerManager?.tabViewController.showInterestIdentityVerificationScreen(controller)
    }

    func reloadAfterMultiAddressResponse() {
        guard let tabControllerManager = tabControllerManager,
              tabControllerManager.tabViewController.isViewLoaded
        else {
            // Nothing to reload
            return
        }
        accountsAndAddressesNavigationController?.reload()
        sideMenuViewController?.reload()
    }

    func logout() {
        showAlert(
            with: .init(
                title: LocalizationConstants.SideMenu.logout,
                message: LocalizationConstants.SideMenu.logoutConfirm,
                actions: [
                    UIAlertAction(
                        title: LocalizationConstants.okString,
                        style: .default
                    ) { [weak self] _ in
                        self?.viewStore.send(.logout)
                    },
                    UIAlertAction(
                        title: LocalizationConstants.cancel,
                        style: .cancel
                    )
                ]
            )
        )
    }
}
