// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureTransactionDomain
import MoneyKit
import PlatformKit
import PlatformUIKit
import RIBs
import SwiftUI
import ToolKit

/// A protocol defining the API for the app's entry point to any `Transaction Flow`.
/// NOTE: Presenting a Transaction Flow can never fail because it's expected for any error to be handled within the flow.
/// Non-recoverable errors should force the user to abandon the flow.
public protocol TransactionsRouterAPI {

    /// Some APIs may not have UIKit available. In this instance we use
    /// `TopMostViewControllerProviding`.
    func presentTransactionFlow(
        to action: TransactionFlowAction
    ) -> AnyPublisher<TransactionFlowResult, Never>

    func presentTransactionFlow(
        to action: TransactionFlowAction,
        from presenter: UIViewController
    ) -> AnyPublisher<TransactionFlowResult, Never>
}

internal final class TransactionsRouter: TransactionsRouterAPI {

    private let featureFlagsService: FeatureFlagsServiceAPI
    private let pendingOrdersService: PendingOrderDetailsServiceAPI
    private let eligibilityService: EligibilityServiceAPI
    private let kycRouter: PlatformUIKit.KYCRouting
    private let alertViewPresenter: AlertViewPresenterAPI
    private let topMostViewControllerProvider: TopMostViewControllerProviding
    private let loadingViewPresenter: LoadingViewPresenting
    private var transactionFlowBuilder: TransactionFlowBuildable
    private let buyFlowBuilder: BuyFlowBuildable
    private let sellFlowBuilder: SellFlowBuildable
    private let signFlowBuilder: SignFlowBuildable
    private let sendFlowBuilder: SendRootBuildable
    private let interestFlowBuilder: InterestTransactionBuilder
    private let withdrawFlowBuilder: WithdrawRootBuildable
    private let depositFlowBuilder: DepositRootBuildable
    private let receiveCoordinator: ReceiveCoordinator
    private let fiatCurrencyService: FiatCurrencySettingsServiceAPI
    @LazyInject var tabSwapping: TabSwapping

    /// Currently retained RIBs router in use.
    private var currentRIBRouter: RIBs.Routing?
    private var cancellables: Set<AnyCancellable> = []

    init(
        featureFlagsService: FeatureFlagsServiceAPI = resolve(),
        pendingOrdersService: PendingOrderDetailsServiceAPI = resolve(),
        kycRouter: PlatformUIKit.KYCRouting = resolve(),
        alertViewPresenter: AlertViewPresenterAPI = resolve(),
        topMostViewControllerProvider: TopMostViewControllerProviding = resolve(),
        loadingViewPresenter: LoadingViewPresenting = LoadingViewPresenter(),
        transactionFlowBuilder: TransactionFlowBuildable = TransactionFlowBuilder(),
        buyFlowBuilder: BuyFlowBuildable = BuyFlowBuilder(analyticsRecorder: resolve()),
        sellFlowBuilder: SellFlowBuildable = SellFlowBuilder(),
        signFlowBuilder: SignFlowBuildable = SignFlowBuilder(),
        sendFlowBuilder: SendRootBuildable = SendRootBuilder(),
        interestFlowBuilder: InterestTransactionBuilder = InterestTransactionBuilder(),
        withdrawFlowBuilder: WithdrawRootBuildable = WithdrawRootBuilder(),
        depositFlowBuilder: DepositRootBuildable = DepositRootBuilder(),
        eligibilityService: EligibilityServiceAPI = resolve(),
        receiveCoordinator: ReceiveCoordinator = ReceiveCoordinator(),
        fiatCurrencyService: FiatCurrencySettingsServiceAPI = resolve()
    ) {
        self.featureFlagsService = featureFlagsService
        self.kycRouter = kycRouter
        self.topMostViewControllerProvider = topMostViewControllerProvider
        self.alertViewPresenter = alertViewPresenter
        self.loadingViewPresenter = loadingViewPresenter
        self.pendingOrdersService = pendingOrdersService
        self.transactionFlowBuilder = transactionFlowBuilder
        self.buyFlowBuilder = buyFlowBuilder
        self.sellFlowBuilder = sellFlowBuilder
        self.signFlowBuilder = signFlowBuilder
        self.sendFlowBuilder = sendFlowBuilder
        self.interestFlowBuilder = interestFlowBuilder
        self.withdrawFlowBuilder = withdrawFlowBuilder
        self.depositFlowBuilder = depositFlowBuilder
        self.eligibilityService = eligibilityService
        self.receiveCoordinator = receiveCoordinator
        self.fiatCurrencyService = fiatCurrencyService
    }

    func presentTransactionFlow(
        to action: TransactionFlowAction
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        guard let viewController = topMostViewControllerProvider.topMostViewController else {
            fatalError("Expected a UIViewController")
        }
        return presentTransactionFlow(to: action, from: viewController)
    }

    func presentTransactionFlow(
        to action: TransactionFlowAction,
        from presenter: UIViewController
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        switch action {
        case .buy:
            return presentTradingCurrencySelectorIfNeeded(from: presenter)
                .flatMap { result -> AnyPublisher<TransactionFlowResult, Never> in
                    guard result == .completed else {
                        return .just(result)
                    }
                    return self.presentBuyTransactionFlow(to: action, from: presenter)
                }
                .eraseToAnyPublisher()

        case .sell,
             .order,
             .swap,
             .interestTransfer,
             .interestWithdraw,
             .sign,
             .send,
             .receive,
             .withdraw,
             .deposit:
            return presentNewTransactionFlow(action, from: presenter)
        }
    }

    private func presentBuyTransactionFlow(
        to action: TransactionFlowAction,
        from presenter: UIViewController
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        eligibilityService.eligibility()
            .receive(on: DispatchQueue.main)
            .handleLoaderForLifecycle(loader: loadingViewPresenter)
            .flatMap { [weak self] eligibility -> AnyPublisher<TransactionFlowResult, Error> in
                guard let self = self else { return .empty() }
                if eligibility.simpleBuyPendingTradesEligible {
                    return self.pendingOrdersService.pendingOrderDetails
                        .asPublisher()
                        .receive(on: DispatchQueue.main)
                        .flatMap { [weak self] orders -> AnyPublisher<TransactionFlowResult, Never> in
                            guard let self = self else { return .empty() }
                            let isAwaitingAction = orders.filter(\.isAwaitingAction)
                            if let order = isAwaitingAction.first {
                                return self.presentNewTransactionFlow(action, from: presenter)
                                    .zip(
                                        self.pendingOrdersService.cancel(order)
                                            .receive(on: DispatchQueue.main)
                                            .ignoreFailure()
                                    )
                                    .map(\.0)
                                    .eraseToAnyPublisher()
                            } else {
                                return self.presentNewTransactionFlow(action, from: presenter)
                            }
                        }
                        .eraseToAnyPublisher()
                } else {
                    return self.presentTooManyPendingOrders(
                        count: eligibility.maxPendingDepositSimpleBuyTrades,
                        from: presenter
                    )
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
                }
            }
            .catch { [weak self] _ -> AnyPublisher<TransactionFlowResult, Never> in
                guard let self = self else { return .empty() }
                return self.presentTooManyPendingOrdersError(from: presenter)
            }
            .eraseToAnyPublisher()
    }
}

extension TransactionsRouter {

    // since we're not attaching a RIB to a RootRouter we have to retain the router and manually activate it
    private func mimicRIBAttachment(router: RIBs.Routing) {
        currentRIBRouter?.interactable.deactivate()
        currentRIBRouter = router
        router.load()
        router.interactable.activate()
    }
}

extension TransactionsRouter {

    // swiftlint:disable:next cyclomatic_complexity
    private func presentNewTransactionFlow(
        _ action: TransactionFlowAction,
        from presenter: UIViewController
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        switch action {
        case .interestWithdraw(let cryptoAccount):
            let listener = InterestTransactionInteractor(transactionType: .withdraw(cryptoAccount))
            let router = interestFlowBuilder.buildWithInteractor(listener)
            router.start()
            mimicRIBAttachment(router: router)
            return listener.publisher

        case .interestTransfer(let cryptoAccount):
            let listener = InterestTransactionInteractor(transactionType: .transfer(cryptoAccount))
            let router = interestFlowBuilder.buildWithInteractor(listener)
            router.start()
            mimicRIBAttachment(router: router)
            return listener.publisher

        case .buy(let cryptoAccount):
            let listener = BuyFlowListener(
                kycRouter: kycRouter,
                alertViewPresenter: alertViewPresenter
            )
            let interactor = BuyFlowInteractor()
            let router = buyFlowBuilder.build(with: listener, interactor: interactor)
            router.start(with: cryptoAccount, order: nil, from: presenter)
            mimicRIBAttachment(router: router)
            return listener.publisher

        case .order(let order):
            let listener = BuyFlowListener(
                kycRouter: kycRouter,
                alertViewPresenter: alertViewPresenter
            )
            let interactor = BuyFlowInteractor()
            let router = buyFlowBuilder.build(with: listener, interactor: interactor)
            router.start(with: nil, order: order, from: presenter)
            mimicRIBAttachment(router: router)
            return listener.publisher

        case .sell(let cryptoAccount):
            let listener = SellFlowListener()
            let interactor = SellFlowInteractor()
            let router = SellFlowBuilder().build(with: listener, interactor: interactor)
            router.start(with: cryptoAccount, from: presenter)
            mimicRIBAttachment(router: router)
            return listener.publisher

        case .swap(let cryptoAccount):
            if cryptoAccount == nil {
                let router = SwapRootBuilder().build()
                presenter.present(router.viewControllable.uiviewController, animated: true, completion: nil)
                mimicRIBAttachment(router: router)
                return .empty()
            } else {
                let listener = SwapRootInteractor()
                let router = transactionFlowBuilder.build(
                    withListener: listener,
                    action: .swap,
                    sourceAccount: cryptoAccount,
                    target: nil
                )
                presenter.present(router.viewControllable.uiviewController, animated: true)
                mimicRIBAttachment(router: router)
                return .empty()
            }

        case .sign(let sourceAccount, let destination):
            let listener = SignFlowListener()
            let interactor = SignFlowInteractor()
            let router = signFlowBuilder.build(with: listener, interactor: interactor)
            router.start(sourceAccount: sourceAccount, destination: destination, presenter: presenter)
            mimicRIBAttachment(router: router)
            return listener.publisher

        case .send(let fromAccount, let toAccount):
            let router = sendFlowBuilder.build()
            switch (fromAccount, toAccount) {
            case (.some(let fromAccount), .some(let toAccount)):
                router.routeToSend(sourceAccount: fromAccount, destination: toAccount)
            case (.some(let fromAccount), _):
                router.routeToSend(sourceAccount: fromAccount)
            default:
                break
            }
            router.routeToSendLanding(navigationBarHidden: true)
            presenter.present(router.viewControllable.uiviewController, animated: true)
            mimicRIBAttachment(router: router)
            return .empty()

        case .receive(let account):
            presenter.present(receiveCoordinator.builder.receive(), animated: true)
            if let account = account {
                receiveCoordinator.routeToReceive(sourceAccount: account)
            }
            return .empty()

        case .withdraw(let fiatAccount):
            let router = withdrawFlowBuilder.build(sourceAccount: fiatAccount)
            router.start()
            mimicRIBAttachment(router: router)
            return .empty()

        case .deposit(let fiatAccount):
            let router = depositFlowBuilder.build(with: fiatAccount)
            router.start()
            mimicRIBAttachment(router: router)
            return .empty()
        }
    }

    private func presentTooManyPendingOrders(
        count: Int,
        from presenter: UIViewController
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        let subject = PassthroughSubject<TransactionFlowResult, Never>()

        func dismiss() {
            presenter.dismiss(animated: true) {
                subject.send(.abandoned)
            }
        }

        presenter.present(
            NavigationView {
                TooManyPendingOrdersView(
                    count: count,
                    viewActivityAction: { [tabSwapping] in
                        tabSwapping.switchToActivity()
                        dismiss()
                    },
                    okAction: dismiss
                )
                .whiteNavigationBarStyle()
                .trailingNavigationButton(.close, action: dismiss)
            }
        )
        return subject.eraseToAnyPublisher()
    }

    /// Checks if the user has a valid trading currency set. If not, it presents a modal asking the user to select one.
    ///
    /// If presented, the modal allows the user to select a trading fiat currency to be the base of transactions. This currency can only be one of the currencies supported for any of our official trading pairs.
    /// At the time of this writing, the supported trading currencies are USD, EUR, and GBP.
    ///
    /// The trading currency should be used to define the fiat inputs in the Enter Amount Screen and to show fiat values in the transaction flow.
    ///
    /// - Note: Checking for a trading currency is only required for the Buy flow at this time. However, it may be required for other flows as well in the future.
    ///
    /// - Returns: A `Publisher` whose result is `TransactionFlowResult.completed` if the user had or has successfully selected a trading currency.
    /// Otherwise, it returns `TransactionFlowResult.abandoned`. In this case, the user should be prevented from entering the desired transaction flow.
    private func presentTradingCurrencySelectorIfNeeded(
        from presenter: UIViewController
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        let viewControllerGenerator = viewControllerForSelectingTradingCurrency
        // 1. Fetch Trading Currency and supported trading currencies
        return fiatCurrencyService.tradingCurrency
            .zip(fiatCurrencyService.supportedFiatCurrencies)
            .receive(on: DispatchQueue.main)
            .flatMap { tradingCurrency, supportedTradingCurrencies -> AnyPublisher<TransactionFlowResult, Never> in
                // 2a. If trading currency matches one of supported currencies, return .completed
                guard !supportedTradingCurrencies.contains(tradingCurrency) else {
                    return .just(.completed)
                }
                // 2b. Otherwise, present new screen, with close => .abandoned, selectCurrency => settingsService.setTradingCurrency
                let subject = PassthroughSubject<TransactionFlowResult, Never>()
                let sortedCurrencies = Array(supportedTradingCurrencies)
                    .sorted(by: { $0.displayCode < $1.displayCode })
                let viewController = viewControllerGenerator(tradingCurrency, sortedCurrencies) { result in
                    presenter.dismiss(animated: true) {
                        subject.send(result)
                        subject.send(completion: .finished)
                    }
                }
                presenter.present(viewController, animated: true, completion: nil)
                return subject.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func viewControllerForSelectingTradingCurrency(
        displayCurrency: FiatCurrency,
        currencies: [FiatCurrency],
        handler: @escaping (TransactionFlowResult) -> Void
    ) -> UIViewController {
        UIHostingController(
            rootView: TradingCurrencySelector(
                store: .init(
                    initialState: .init(
                        displayCurrency: displayCurrency,
                        currencies: currencies
                    ),
                    reducer: TradingCurrency.reducer,
                    environment: .init(
                        closeHandler: {
                            handler(.abandoned)
                        },
                        selectionHandler: { [weak self] selectedCurrency in
                            guard let self = self else {
                                return
                            }
                            self.fiatCurrencyService
                                .update(tradingCurrency: selectedCurrency, context: .simpleBuy)
                                .map(TransactionFlowResult.completed)
                                .receive(on: DispatchQueue.main)
                                .handleLoaderForLifecycle(loader: self.loadingViewPresenter)
                                .sink(receiveValue: handler)
                                .store(in: &self.cancellables)
                        }
                    )
                )
            )
        )
    }

    private func presentTooManyPendingOrdersError(
        from presenter: UIViewController
    ) -> AnyPublisher<TransactionFlowResult, Never> {
        let subject = PassthroughSubject<TransactionFlowResult, Never>()

        func dismiss() {
            presenter.dismiss(animated: true) {
                subject.send(.abandoned)
            }
        }

        presenter.present(
            NavigationView {
                TooManyPendingOrdersErrorView(
                    okAction: dismiss
                )
                .whiteNavigationBarStyle()
                .trailingNavigationButton(.close, action: dismiss)
            }
        )
        return subject.eraseToAnyPublisher()
    }
}
