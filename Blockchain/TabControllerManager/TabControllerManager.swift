// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import FeatureActivityUI
import FeatureDashboardUI
import FeatureTransactionDomain
import FeatureTransactionUI
import MoneyKit
import PlatformKit
import PlatformUIKit
import RIBs
import RxSwift
import ToolKit

final class TabControllerManager: NSObject {

    // MARK: - Properties

    @objc let tabViewController: TabViewController

    // MARK: - Private Properties

    private var activityNavigationController: UINavigationController!
    private var dashboardNavigationController: UINavigationController!
    private var receiveNavigationViewController: UINavigationController!
    private var sendP2ViewController: UIViewController!
    private var swapViewController: UIViewController!
    private var swapRouter: ViewableRouting!
    private var sendRouter: SendRootRouting!
    private var receiveRouter: ReceiveRouterAPI!
    private var depositRouter: DepositRootRouting!
    private var withdrawRouter: WithdrawRootRouting!

    private var analyticsEventRecorder: AnalyticsEventRecorderAPI
    private let drawerRouter: DrawerRouting
    private let receiveCoordinator: ReceiveCoordinator
    private let featureConfigurator: FeatureConfiguring
    private let internalFeatureFlag: InternalFeatureFlagServiceAPI
    private let coincore: CoincoreAPI
    private let disposeBag = DisposeBag()
    @LazyInject private var walletManager: WalletManager

    init(
        receiveCoordinator: ReceiveCoordinator = resolve(),
        analyticsEventRecorder: AnalyticsEventRecorderAPI = resolve(),
        featureConfigurator: FeatureConfiguring = resolve(),
        internalFeatureFlag: InternalFeatureFlagServiceAPI = resolve(),
        coincore: CoincoreAPI = resolve(),
        drawerRouter: DrawerRouting = resolve()
    ) {
        self.analyticsEventRecorder = analyticsEventRecorder
        self.featureConfigurator = featureConfigurator
        self.internalFeatureFlag = internalFeatureFlag
        self.coincore = coincore
        self.receiveCoordinator = receiveCoordinator
        self.drawerRouter = drawerRouter
        tabViewController = TabViewController.makeFromStoryboard()
        super.init()
        tabViewController.delegate = self
    }

    // MARK: - Show

    func showDashboard() {
        if dashboardNavigationController == nil {
            let builder = DashboardScreenBuilder()
            dashboardNavigationController = UINavigationController(rootViewController: builder.build())
        }
        tabViewController.setActiveViewController(
            dashboardNavigationController,
            animated: true,
            index: Constants.Navigation.tabDashboard
        )
    }

    @objc func showTransactions() {
        drawerRouter.closeSideMenu()
        if activityNavigationController == nil {
            activityNavigationController = UINavigationController(rootViewController: ActivityScreenViewController())
        }
        tabViewController.setActiveViewController(
            activityNavigationController,
            animated: true,
            index: Constants.Navigation.tabTransactions
        )
    }

    private func loadSwap() {
        guard swapViewController == nil else { return }
        guard swapRouter == nil else { return }

        let router = SwapRootBuilder().build()
        swapViewController = router.viewControllable.uiviewController
        swapRouter = router
        router.interactable.activate()
        router.load()
    }

    func showSwap() {
        loadSwap()
        tabViewController.setActiveViewController(
            swapViewController,
            animated: true,
            index: Constants.Navigation.tabSwap
        )
    }

    private func loadSend() {
        guard sendP2ViewController == nil else { return }
        let router = SendRootBuilder().build()
        sendP2ViewController = router.viewControllable.uiviewController
        sendRouter = router
        sendRouter.routeToSendLanding()
        sendRouter.interactable.activate()
        sendRouter.load()
    }

    private func setSendAsActive() {
        tabViewController.setActiveViewController(
            sendP2ViewController,
            animated: true,
            index: Constants.Navigation.tabSend
        )
    }

    private func loadReceive() {
        if receiveNavigationViewController == nil {
            receiveNavigationViewController = UINavigationController(
                rootViewController: receiveCoordinator.builder.receive()
            )
        }
    }

    func deposit(into account: BlockchainAccount) {
        let router = DepositRootBuilder().build(with: account as! FiatAccount)
        depositRouter = router
        depositRouter.start()
    }

    func withdraw(from account: BlockchainAccount) {
        let router = WithdrawRootBuilder().build(sourceAccount: account as! FiatAccount)
        withdrawRouter = router
        withdrawRouter.start()
    }

    func withdraw(from account: BlockchainAccount, target: TransactionTarget) {
        unimplemented()
    }

    func send(from account: BlockchainAccount) {
        loadSend()
        sendRouter.routeToSend(sourceAccount: account)
    }

    func send(from account: BlockchainAccount, target: TransactionTarget) {
        loadSend()
        sendRouter.routeToSend(sourceAccount: account, destination: target)
    }

    func showSend(cryptoCurrency: CryptoCurrency) {
        loadSend()
        setSendAsActive()
    }

    func showSend() {
        loadSend()
        setSendAsActive()
    }

    func receive(into account: BlockchainAccount) {
        loadReceive()
        receiveCoordinator.routeToReceive(sourceAccount: account)
    }

    func showReceive() {
        loadReceive()
        tabViewController.setActiveViewController(
            receiveNavigationViewController,
            animated: true,
            index: Constants.Navigation.tabReceive
        )
    }

    // MARK: BitPay

    func setupBitpayPayment(from url: URL) {
        let data = url.absoluteString
        let asset = coincore[.coin(.bitcoin)]
        let transactionPair = Single.zip(
            BitPayInvoiceTarget.make(from: data, asset: .coin(.bitcoin)),
            asset.defaultAccount.asSingle()
        )
        BitPayInvoiceTarget
            .isBitPay(data)
            .andThen(BitPayInvoiceTarget.isBitcoin(data))
            .andThen(transactionPair)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] target, defaultAccount in
                UIView.animate(
                    withDuration: 0.3,
                    animations: { [weak self] in
                        self?.showSend()
                    },
                    completion: { [weak self] _ in
                        self?.send(from: defaultAccount, target: target)
                    }
                )
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - TabViewControllerDelegate

extension TabControllerManager: TabViewControllerDelegate {
    func tabViewController(_ tabViewController: TabViewController, viewDidAppear animated: Bool) {
        // NOOP
    }

    // MARK: - View Life Cycle

    func tabViewControllerViewDidLoad(_ tabViewController: TabViewController) {}

    func sendClicked() {
        showSend()
        analyticsEventRecorder.record(event:
            AnalyticsEvents.New.Send.sendReceiveClicked(origin: .navigation, type: .send)
        )
    }

    func receiveClicked() {
        showReceive()
        analyticsEventRecorder.record(event:
            AnalyticsEvents.New.Send.sendReceiveClicked(origin: .navigation, type: .receive)
        )
    }

    func transactionsClicked() {
        analyticsEventRecorder.record(
            event: AnalyticsEvents.Transactions.transactionsTabItemClick
        )
        showTransactions()
    }

    func dashBoardClicked() {
        showDashboard()
    }

    func swapClicked() {
        analyticsEventRecorder.record(events: [
            AnalyticsEvents.Swap.swapTabItemClick,
            AnalyticsEvents.New.Swap.swapClicked(origin: .navigation)
        ])
        showSwap()
    }
}
