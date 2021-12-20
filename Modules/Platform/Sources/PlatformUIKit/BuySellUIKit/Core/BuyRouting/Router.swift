// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import DIKit
import FeatureOpenBankingUI
import Localization
import MoneyKit
import PlatformKit
import RxSwift
import SafariServices
import ToolKit

public enum RouterError: Error {
    case kyc(KYCRouterError)
}

public protocol RouterAPI: AnyObject {
    func setup(startImmediately: Bool)
    func start()
    func start(skipIntro: Bool)
    func next(to state: StateService.State)
    func previous(from state: StateService.State)
    func showCryptoSelectionScreen()
    func showFailureAlert()

    func presentEmailVerificationIfNeeded() -> AnyPublisher<KYCRoutingResult, RouterError>
    func presentKYCIfNeeded() -> AnyPublisher<KYCRoutingResult, RouterError>
}

// swiftlint:disable type_body_length
// swiftlint:disable file_length

/// This object is used as a router for Simple-Buy flow
public final class Router: RouterAPI {

    // MARK: - Types

    private typealias AnalyticsEvent = AnalyticsEvents.SimpleBuy

    // MARK: - Private Properties

    private let stateService: StateServiceAPI
    private let kycRouter: KYCRouterAPI
    private let newKYCRouter: KYCRouting
    private let supportedPairsInteractor: SupportedPairsInteractorServiceAPI
    private let paymentMethodTypesService: PaymentMethodTypesServiceAPI
    private let settingsService: FiatCurrencySettingsServiceAPI
    private let tiersService: KYCTiersServiceAPI
    private let cryptoSelectionService: CryptoCurrencySelectionServiceAPI
    private let navigationRouter: NavigationRouterAPI
    private let alertViewPresenter: AlertViewPresenterAPI
    private let paymentAccountService: PaymentAccountServiceAPI
    private var stripeClient: StripeUIClientAPI

    private var cardRouter: CardRouter!

    /// A kyc subscription dispose bag
    private var kycDisposeBag = DisposeBag()

    /// A general dispose bag
    private let disposeBag = DisposeBag()
    private var bag: Set<AnyCancellable> = []

    private let builder: Buildable

    /// The router for payment methods flow
    private var achFlowRouter: ACHFlowStarter?
    /// The router for linking a new bank
    private var linkBankFlowRouter: LinkBankFlowStarter?

    private let analyticsRecorder: AnalyticsEventRecorderAPI

    // MARK: - Setup

    public init(
        builder: Buildable,
        currency: CryptoCurrency,
        navigationRouter: NavigationRouterAPI = resolve(),
        paymentMethodTypesService: PaymentMethodTypesServiceAPI = resolve(),
        settingsService: CompleteSettingsServiceAPI = resolve(),
        supportedPairsInteractor: SupportedPairsInteractorServiceAPI = resolve(),
        tiersService: KYCTiersServiceAPI = resolve(),
        alertViewPresenter: AlertViewPresenterAPI = resolve(),
        kycRouter: KYCRouterAPI = resolve(), // TODO: merge with the following or remove (IOS-4471)
        newKYCRouter: KYCRouting = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve(),
        paymentAccountService: PaymentAccountServiceAPI = resolve(),
        stripeClient: StripeUIClientAPI = resolve()
    ) {
        self.navigationRouter = navigationRouter
        self.supportedPairsInteractor = supportedPairsInteractor
        self.settingsService = settingsService
        self.alertViewPresenter = alertViewPresenter
        stateService = builder.stateService
        self.tiersService = tiersService
        self.kycRouter = kycRouter
        self.newKYCRouter = newKYCRouter
        self.builder = builder
        self.analyticsRecorder = analyticsRecorder
        self.paymentAccountService = paymentAccountService
        self.stripeClient = stripeClient

        let cryptoSelectionService = CryptoCurrencySelectionService(
            service: supportedPairsInteractor,
            defaultSelectedData: currency
        )
        self.paymentMethodTypesService = paymentMethodTypesService
        self.cryptoSelectionService = cryptoSelectionService
    }

    public func showCryptoSelectionScreen() {
        typealias LocalizedString = LocalizationConstants.SimpleBuy.CryptoSelectionScreen
        let interactor = SelectionScreenInteractor(service: cryptoSelectionService)
        let presenter = SelectionScreenPresenter(
            title: LocalizedString.title,
            searchBarPlaceholder: LocalizedString.searchBarPlaceholder,
            interactor: interactor
        )
        let viewController = SelectionScreenViewController(presenter: presenter)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationRouter.navigationControllerAPI?.present(navigationController, animated: true, completion: nil)
    }

    public func showFailureAlert() {
        alertViewPresenter
            .error(in: navigationRouter.topMostViewControllerProvider.topMostViewController) { [weak self] in
                self?.navigationRouter.navigationControllerAPI?.dismiss(animated: true, completion: nil)
            }
    }

    /// Should be called once
    public func setup(startImmediately: Bool) {
        stateService.action
            .observe(on: MainScheduler.asyncInstance)
            .bindAndCatch(weak: self) { (self, action) in
                switch action {
                case .previous(let state):
                    self.previous(from: state)
                case .next(let state):
                    self.next(to: state)
                case .dismiss:
                    self.navigationRouter.navigationControllerAPI?.dismiss(animated: true, completion: nil)
                }
            }
            .disposed(by: disposeBag)
        if startImmediately {
            stateService.nextRelay.accept(())
        }
    }

    /// Should be called once
    public func start() {
        start(skipIntro: false)
    }

    public func start(skipIntro: Bool) {
        if skipIntro {
            stateService.cache.mutate { $0[.hasShownIntroScreen] = true }
        }
        setup(startImmediately: true)
    }

    public func next(to state: StateService.State) {
        switch state {
        case .intro:
            showIntroScreen()
        case .changeFiat:
            settingsService
                .displayCurrency
                .asSingle()
                .observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] currency in
                    self?.showFiatCurrencyChangeScreen(selectedCurrency: currency)
                })
                .disposed(by: disposeBag)
        case .selectFiat:
            settingsService
                .displayCurrency
                .asSingle()
                .observe(on: MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] currency in
                    self?.showFiatCurrencySelectionScreen(selectedCurrency: currency)
                })
                .disposed(by: disposeBag)
        case .unsupportedFiat(let currency):
            showInelligibleCurrency(with: currency)
        case .buy:
            showBuyCryptoScreen()
        case .checkout(let data):
            showCheckoutScreen(with: data)
        case .pendingOrderDetails(let data):
            showCheckoutScreen(with: data)
        case .authorizeCard(let data):
            showCardAuthorization(with: data)
        case .authorizeOpenBanking(let data):
            showOpenBankingAuthorization(with: data)
        case .pendingOrderCompleted(orderDetails: let orderDetails):
            showPendingOrderCompletionScreen(for: orderDetails)
        case .paymentMethods:
            showPaymentMethodsScreen()
        case .bankTransferDetails(let data):
            showBankTransferDetailScreen(with: data)
        case .fundsTransferDetails(let currency, let isOriginPaymentMethods, let isOriginDeposit):
            guard let fiatCurrency = currency.fiatCurrency else { return }
            showFundsTransferDetailsScreen(
                with: fiatCurrency,
                shouldDismissModal: isOriginPaymentMethods,
                isOriginDeposit: isOriginDeposit
            )
        case .transferCancellation(let data):
            showTransferCancellation(with: data)
        case .kyc:
            showKYC(afterDismissal: true)
        case .kycBeforeCheckout:
            showKYC(afterDismissal: false)
        case .showURL(let url):
            showSafariViewController(with: url)
        case .pendingKycApproval, .ineligible:
            /// Show pending KYC approval for `ineligible` state as well, since the expected poll result would be
            /// ineligible anyway
            showPendingKycApprovalScreen()
        case .linkBank:
            showLinkBankFlow()
        case .linkCard:
            showLinkCardFlow()
        case .addCard(let data):
            startCardAdditionFlow(with: data)
        case .inactive:
            navigationRouter.navigationControllerAPI?.dismiss(animated: true, completion: nil)
        }
    }

    public func previous(from state: StateService.State) {
        switch state {
        // Some independent flows which dismiss themselves.
        // Therefore, do nothing.
        case .kyc, .selectFiat, .changeFiat, .unsupportedFiat, .addCard, .linkBank:
            break
        case .paymentMethods, .bankTransferDetails, .fundsTransferDetails:
            navigationRouter.topMostViewControllerProvider
                .topMostViewController?
                .dismiss(animated: true)
        default:
            navigationRouter.dismiss()
        }
    }

    private func showLinkCardFlow() {
        if navigationRouter.navigationControllerAPI?.presentedViewControllerAPI != nil {
            navigationRouter.dismiss { [weak self] in
                self?.startCardAdditionFlow(with: nil)
            }
        } else {
            startCardAdditionFlow(with: nil)
        }
    }

    private func startCardAdditionFlow(with checkoutData: CheckoutData?) {
        let interactor = stateService.cardRoutingInteractor(
            with: checkoutData
        )
        let builder = CardComponentBuilder(
            routingInteractor: interactor,
            paymentMethodTypesService: paymentMethodTypesService
        )
        cardRouter = CardRouter(
            interactor: interactor,
            builder: builder,
            routingType: .modal
        )
        // NOTE: This is a temporary patch of the card router intialization, and should not be called directly.
        // The reason that it is called directly now is that the `Self` is not a RIBs based.
        cardRouter.load()
    }

    private func showSafariViewController(with url: URL) {
        navigationRouter.dismiss { [weak self] in
            guard let self = self else { return }
            let controller = SFSafariViewController(url: url)
            controller.modalPresentationStyle = .overFullScreen
            guard let top = self.navigationRouter.topMostViewControllerProvider.topMostViewController else { return }
            top.present(controller, animated: true, completion: nil)
        }
    }

    private func showFiatCurrencyChangeScreen(selectedCurrency: FiatCurrency) {
        let selectionService = FiatCurrencySelectionService(
            defaultSelectedData: selectedCurrency,
            provider: FiatCurrencySelectionProvider()
        )
        let interactor = SelectionScreenInteractor(service: selectionService)
        let presenter = SelectionScreenPresenter(
            title: LocalizationConstants.localCurrency,
            description: LocalizationConstants.localCurrencyDescription,
            searchBarPlaceholder: LocalizationConstants.Settings.SelectCurrency.searchBarPlaceholder,
            interactor: interactor
        )
        let viewController = SelectionScreenViewController(presenter: presenter)
        viewController.isModalInPresentation = true

        analyticsRecorder.record(event: AnalyticsEvent.sbCurrencySelectScreen)

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationRouter.navigationControllerAPI?.present(navigationController, animated: true, completion: nil)

        interactor.selectedIdOnDismissal
            .map { FiatCurrency(code: $0)! }
            .flatMap(weak: self) { (self, currency) -> Single<FiatCurrency> in
                // TICKET: IOS-3144
                self.settingsService
                    .update(
                        displayCurrency: currency,
                        context: .simpleBuy
                    )
                    .asSingle()
                    .asCompletable()
                    .andThen(Single.just(currency))
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] currency in
                    guard let self = self else { return }
                    // TODO: Remove this and `fiatCurrencySelected` once `ReceiveBTC` and
                    /// `SendBTC` are replaced with Swift implementations.
                    NotificationCenter.default.post(name: .fiatCurrencySelected, object: nil)
                    self.analyticsRecorder.record(event: AnalyticsEvent.sbCurrencySelected(currencyCode: currency.code))

                    self.stateService.previousRelay.accept(())
                })
            .disposed(by: disposeBag)
    }

    private func showFiatCurrencySelectionScreen(selectedCurrency: FiatCurrency) {
        let selectionService = FiatCurrencySelectionService(defaultSelectedData: selectedCurrency)
        let interactor = SelectionScreenInteractor(service: selectionService)
        let presenter = SelectionScreenPresenter(
            title: LocalizationConstants.localCurrency,
            description: LocalizationConstants.localCurrencyDescription,
            shouldPreselect: false,
            searchBarPlaceholder: LocalizationConstants.Settings.SelectCurrency.searchBarPlaceholder,
            interactor: interactor
        )
        let viewController = SelectionScreenViewController(presenter: presenter)
        viewController.isModalInPresentation = true

        if navigationRouter.navigationControllerAPI == nil {
            navigationRouter.present(viewController: viewController)
        } else {
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationRouter.navigationControllerAPI?.present(navigationController, animated: true, completion: nil)
        }

        interactor.dismiss
            .bind { [weak self] in
                self?.stateService.previousRelay.accept(())
            }
            .disposed(by: disposeBag)

        interactor.selectedIdOnDismissal
            .map { FiatCurrency(code: $0)! }
            .flatMap(weak: self) { (self, currency) -> Single<(FiatCurrency, Bool)> in

                let isCurrencySupported = self.supportedPairsInteractor
                    .fetch()
                    .map { !$0.pairs.isEmpty }
                    .take(1)
                    .asSingle()

                // TICKET: IOS-3144
                return self.settingsService
                    .update(
                        displayCurrency: currency,
                        context: .simpleBuy
                    )
                    .asSingle()
                    .asCompletable()
                    .andThen(Single.zip(
                        Single.just(currency),
                        isCurrencySupported
                    ))
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] value in
                    guard let self = self else { return }
                    // TODO: Remove this and `fiatCurrencySelected` once `ReceiveBTC` and
                    /// `SendBTC` are replaced with Swift implementations.
                    NotificationCenter.default.post(name: .fiatCurrencySelected, object: nil)
                    self.analyticsRecorder.record(event: AnalyticsEvent.sbCurrencySelected(currencyCode: value.0.code))

                    let isFiatCurrencySupported = value.1
                    let currency = value.0

                    self.navigationRouter.dismiss {
                        self.stateService.previousRelay.accept(())
                        if !isFiatCurrencySupported {
                            self.stateService.ineligible(with: currency)
                        } else {
                            self.stateService.currencySelected()
                        }
                    }
                })
            .disposed(by: disposeBag)
    }

    public func presentEmailVerificationIfNeeded() -> AnyPublisher<KYCRoutingResult, RouterError> {
        guard let viewController = navigationRouter.topMostViewControllerProvider.topMostViewController else {
            fatalError("This is not supposed to be nil. It shouldn't even be optional, probably...")
        }
        return newKYCRouter
            .presentEmailVerificationIfNeeded(from: viewController)
            .mapError(RouterError.kyc)
            .eraseToAnyPublisher()
    }

    public func presentKYCIfNeeded() -> AnyPublisher<KYCRoutingResult, RouterError> {
        guard let viewController = navigationRouter.topMostViewControllerProvider.topMostViewController else {
            fatalError("This is not supposed to be nil. It shouldn't even be optional, probably...")
        }
        // Buy requires Tier 1 for SDD users, Tier 2 for everyone else. Requiring Tier 1 will ensure the SDD check is done.
        return newKYCRouter
            .presentKYCIfNeeded(from: viewController, requiredTier: .tier1)
            .mapError(RouterError.kyc)
            .eraseToAnyPublisher()
    }

    private func showPaymentMethodsScreen() {
        let builder = ACHFlowRootBuilder(stateService: stateService)
        // we need to pass the the navigation controller so we can present and dismiss from within the flow.
        let router = builder.build(presentingController: navigationRouter.navigationControllerAPI)
        achFlowRouter = router
        let flowDimissed: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.achFlowRouter = nil
        }
        router.startFlow(flowDismissed: flowDimissed)
    }

    private func showLinkBankFlow() {
        let builder = LinkBankFlowRootBuilder()
        // we need to pass the the navigation controller so we can present and dismiss from within the flow.
        let router = builder.build()
        linkBankFlowRouter = router
        let flowDismissed: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.linkBankFlowRouter = nil
        }
        analyticsRecorder.record(event: AnalyticsEvents.New.Withdrawal.linkBankClicked(origin: .buy))
        router.startFlow()
            .takeUntil(.inclusive, predicate: { $0.isCloseEffect })
            .skip { $0.shouldSkipEffect }
            .subscribe(onNext: { [weak self] effect in
                guard let self = self else { return }
                guard case .closeFlow(let isInteractive) = effect, !isInteractive else {
                    self.stateService.previousRelay.accept(())
                    flowDismissed()
                    return
                }
                self.stateService.previousRelay.accept(())
                self.navigationRouter.navigationControllerAPI?.dismiss(animated: true, completion: flowDismissed)
            })
            .disposed(by: disposeBag)
    }

    private func showInelligibleCurrency(with currency: FiatCurrency) {
        let presenter = IneligibleCurrencyScreenPresenter(
            currency: currency,
            stateService: stateService
        )
        let controller = IneligibleCurrencyViewController(presenter: presenter)
        controller.transitioningDelegate = sheetPresenter
        controller.modalPresentationStyle = .custom
        analyticsRecorder.record(event: AnalyticsEvent.sbCurrencyUnsupported)
        navigationRouter.topMostViewControllerProvider
            .topMostViewController?
            .present(controller, animated: true, completion: nil)
    }

    /// Shows the checkout details screen
    private func showBankTransferDetailScreen(with data: CheckoutData) {
        let interactor = BankTransferDetailScreenInteractor(
            checkoutData: data
        )

        let webViewRouter = WebViewRouter(
            topMostViewControllerProvider: navigationRouter.topMostViewControllerProvider
        )

        let presenter = BankTransferDetailScreenPresenter(
            webViewRouter: webViewRouter,
            interactor: interactor,
            stateService: stateService
        )
        let viewController = DetailsScreenViewController(presenter: presenter)
        navigationRouter.present(viewController: viewController)
    }

    private func showFundsTransferDetailsScreen(
        with fiatCurrency: FiatCurrency,
        shouldDismissModal: Bool,
        isOriginDeposit: Bool
    ) {
        let viewController = builder.fundsTransferDetailsViewController(
            for: fiatCurrency,
            isOriginDeposit: isOriginDeposit
        )
        if shouldDismissModal {
            navigationRouter.topMostViewControllerProvider
                .topMostViewController?
                .dismiss(animated: true) { [weak self] in
                    self?.navigationRouter
                        .navigationControllerAPI?
                        .present(viewController, animated: true, completion: nil)
                }
        } else {
            navigationRouter.present(
                viewController: viewController,
                using: .modalOverTopMost
            )
        }
    }

    /// Shows the cancellation modal
    private func showTransferCancellation(with data: CheckoutData) {
        let interactor = TransferCancellationInteractor(
            checkoutData: data
        )

        let presenter = TransferCancellationScreenPresenter(
            routingInteractor: BuyTransferCancellationRoutingInteractor(
                stateService: stateService
            ),
            currency: data.outputCurrency,
            interactor: interactor
        )
        let viewController = TransferCancellationViewController(presenter: presenter)
        viewController.transitioningDelegate = sheetPresenter
        viewController.modalPresentationStyle = .custom
        navigationRouter.topMostViewControllerProvider
            .topMostViewController?
            .present(viewController, animated: true, completion: nil)
    }

    /// Shows the checkout screen
    private func showCheckoutScreen(with data: CheckoutData) {
        let orderInteractor: OrderCheckoutInteracting
        switch data.order.paymentMethod {
        case .card:
            orderInteractor = BuyOrderCardCheckoutInteractor(
                cardInteractor: CardOrderCheckoutInteractor()
            )
        case .funds, .bankAccount, .bankTransfer:
            orderInteractor = BuyOrderFundsCheckoutInteractor(
                fundsAndBankInteractor: FundsAndBankOrderCheckoutInteractor()
            )
        }

        let interactor = CheckoutScreenInteractor(
            orderCheckoutInterator: orderInteractor,
            checkoutData: data
        )
        let presenter = CheckoutScreenPresenter(
            checkoutRouting: BuyCheckoutRoutingInteractor(
                stateService: stateService
            ),
            contentReducer: BuyCheckoutScreenContentReducer(data: data),
            interactor: interactor
        )
        let viewController = DetailsScreenViewController(presenter: presenter)
        navigationRouter.present(viewController: viewController)
    }

    private func showPendingOrderCompletionScreen(for orderDetails: OrderDetails) {
        let interactor = PendingOrderStateScreenInteractor(
            orderDetails: orderDetails
        )
        let presenter = PendingOrderStateScreenPresenter(
            routingInteractor: BuyPendingOrderRoutingInteractor(stateService: stateService),
            interactor: interactor
        )
        let viewController = PendingStateViewController(
            presenter: presenter
        )
        navigationRouter.present(viewController: viewController)
    }

    private func showCardAuthorization(with data: OrderDetails) {
        let interactor = CardAuthorizationScreenInteractor(
            routingInteractor: stateService
        )

        let presenter = CardAuthorizationScreenPresenter(
            interactor: interactor,
            data: data.authorizationData!
        )

        guard let authorizationData = data.authorizationData,
              case .required(let params) = authorizationData.state
        else {
            presenter.redirect()
            return
        }

        switch params.cardAcquirer {
        case .stripe:
            stripeClient.confirmPayment(authorizationData, with: presenter)
        case .everyPay, .checkout:
            let viewController = CardAuthorizationScreenViewController(
                presenter: presenter
            )
            navigationRouter.present(viewController: viewController)
        case .unknown:
            presenter.redirect()
        }
    }

    private func showOpenBankingAuthorization(with data: CheckoutData) {

        guard let linkedBank = data.linkedBankData else {
            fatalError("[impossible] Tried to authorise via OpenBanking without a selected bank")
        }

        guard let fiatValue = data.fiatValue else {
            fatalError("[impossible] Tried to authorise via OpenBanking without a fiat currency")
        }

        let viewController = OpenBankingViewController(
            order: .init(data.order),
            from: OpenBanking.BankAccount(linkedBank),
            environment: .init(
                showTransferDetails: { [weak stateService] in
                    stateService?.showFundsTransferDetails(for: fiatValue.currency, isOriginDeposit: false)
                },
                dismiss: { [weak navigationRouter] in
                    navigationRouter?.dismiss(using: .modalOverTopMost)
                },
                cancel: { [weak navigationRouter] in
                    navigationRouter?.navigationControllerAPI?.popToRootViewControllerAnimated(animated: true)
                },
                currency: fiatValue.code
            )
        )

        viewController.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleOpenBanking(
                    order: data.order,
                    currency: fiatValue.currency,
                    event: event
                )
            }
            .store(withLifetimeOf: viewController)

        navigationRouter.present(viewController: viewController)
    }

    private func handleOpenBanking(
        order: OrderDetails,
        currency: FiatCurrency,
        event: Result<Void, OpenBanking.Error>
    ) {
        switch event {
        case .success:
            stateService.authorizedOpenBanking()
        case .failure:
            break
        }
    }

    /// Show the pending kyc screen
    private func showPendingKycApprovalScreen() {
        let dismissControllerOnSuccess: () -> Void = { [weak self] in
            self?.navigationRouter.pop(animated: true)
        }
        let interactor = KYCPendingInteractor()
        let presenter = KYCPendingPresenter(
            stateService: stateService,
            interactor: interactor,
            dismissControllerOnSuccess: dismissControllerOnSuccess
        )
        let viewController = PendingStateViewController(presenter: presenter)
        navigationRouter.present(viewController: viewController, using: .navigationFromCurrent)
    }

    private func showKYC(afterDismissal: Bool) {
        guard let kycRootViewController = navigationRouter.navigationControllerAPI as? UIViewController else {
            return
        }

        kycDisposeBag = DisposeBag()
        kycRouter.kycStopped
            .take(1)
            .observe(on: MainScheduler.instance)
            .bindAndCatch(to: stateService.previousRelay)
            .disposed(by: kycDisposeBag)

        let finished = kycRouter.kycFinished
            .take(1)
            .observe(on: MainScheduler.instance)
            .share()

        // tier 2, silver +, etc. can buy. Only tier 0 and 1 can't.
        // so, observe KYC and check for a valid tier that can buy and move forward or backward accordingly.
        finished
            .filter { $0 == .tier2 }
            .mapToVoid()
            .bindAndCatch(to: stateService.nextRelay)
            .disposed(by: kycDisposeBag)

        let sddVerificationCheck = finished
            // when kyc is stopped and the user is not Tier 2 verified
            .filter { $0 != .tier2 }
            // first check if the user is SDD verified
            .flatMap(weak: self) { (self, tier) -> Observable<Bool> in
                self.tiersService.checkSimplifiedDueDiligenceVerification(for: tier, pollUntilComplete: false)
                    .asObservable()
            }
            // ensure we can subscribe for multiple scenarios
            .share()

        // if the user is NOT SDD verified, we cannot proceed, so go back
        sddVerificationCheck
            .filter { $0 == false }
            .mapToVoid()
            .bindAndCatch(to: stateService.previousRelay)
            .disposed(by: kycDisposeBag)

        // if the user is SDD verified, we can proceed to buy
        sddVerificationCheck
            .filter { $0 == true }
            .mapToVoid()
            .bindAndCatch(to: stateService.nextRelay)
            .disposed(by: kycDisposeBag)

        if afterDismissal {
            navigationRouter.topMostViewControllerProvider
                .topMostViewController?
                .dismiss(animated: true) { [weak self] in
                    self?.kycRouter.start(
                        tier: .tier2,
                        parentFlow: .simpleBuy,
                        from: kycRootViewController
                    )
                }
        } else {
            tiersService
                .tiers
                .asSingle()
                .subscribe { [kycRouter] tiersResponse in
                    kycRouter.start(
                        tier: tiersResponse.latestApprovedTier,
                        parentFlow: .simpleBuy,
                        from: kycRootViewController
                    )
                } onFailure: { [kycRouter] error in
                    Logger.shared.error(String(describing: error))
                    kycRouter.start(
                        tier: .tier0,
                        parentFlow: .simpleBuy,
                        from: kycRootViewController
                    )
                }
                .disposed(by: kycDisposeBag)
        }
    }

    /// Shows buy-crypto screen using a specified presentation type
    private func showBuyCryptoScreen() {
        let interactor = BuyCryptoScreenInteractor(
            paymentMethodTypesService: paymentMethodTypesService,
            cryptoCurrencySelectionService: cryptoSelectionService
        )

        let presenter = BuyCryptoScreenPresenter(
            router: self,
            stateService: stateService,
            interactor: interactor
        )
        let viewController = EnterAmountScreenViewController(presenter: presenter)

        navigationRouter.present(viewController: viewController)
    }

    /// Shows intro screen using a specified presentation type
    private func showIntroScreen() {
        let presenter = BuyIntroScreenPresenter(
            stateService: stateService
        )
        let viewController = BuyIntroScreenViewController(presenter: presenter)
        navigationRouter.present(viewController: viewController)
    }

    private lazy var sheetPresenter: BottomSheetPresenting = {
        BottomSheetPresenting(ignoresBackgroundTouches: true)
    }()
}
