// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import DIKit
import FeatureOpenBankingUI
import FeatureTransactionDomain
import Localization
import PlatformKit
import PlatformUIKit
import RIBs
import RxSwift
import SwiftUI
import ToolKit

protocol TransactionFlowInteractable: Interactable,
    EnterAmountPageListener,
    ConfirmationPageListener,
    AccountPickerListener,
    PendingTransactionPageListener,
    TargetSelectionPageListener
{

    var router: TransactionFlowRouting? { get set }
    var listener: TransactionFlowListener? { get set }

    func didSelectSourceAccount(account: BlockchainAccount)
    func didSelectDestinationAccount(target: TransactionTarget)
}

public protocol TransactionFlowViewControllable: ViewControllable {
    func present(viewController: ViewControllable?, animated: Bool)
    func replaceRoot(viewController: ViewControllable?, animated: Bool)
    func push(viewController: ViewControllable?)
    func dismiss()
    func pop()
}

typealias TransactionViewableRouter = ViewableRouter<TransactionFlowInteractable, TransactionFlowViewControllable>

final class TransactionFlowRouter: TransactionViewableRouter, TransactionFlowRouting {

    private var paymentMethodLinker: PaymentMethodLinkerAPI
    private var bankWireLinker: BankWireLinkerAPI
    private var cardLinker: CardLinkerAPI
    private let alertViewPresenter: AlertViewPresenterAPI
    private let topMostViewControllerProvider: TopMostViewControllerProviding

    private var linkBankFlowRouter: LinkBankFlowStarter?
    private var securityRouter: PaymentSecurityRouter?
    private let kycRouter: PlatformUIKit.KYCRouting
    private let transactionsRouter: TransactionsRouterAPI
    private let featureFlagsService: FeatureFlagsServiceAPI

    private let bottomSheetPresenter = BottomSheetPresenting(ignoresBackgroundTouches: true)

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    var isDisplayingRootViewController: Bool {
        viewController.uiviewController.presentedViewController == nil
    }

    init(
        interactor: TransactionFlowInteractable,
        viewController: TransactionFlowViewControllable,
        paymentMethodLinker: PaymentMethodLinkerAPI = resolve(),
        bankWireLinker: BankWireLinkerAPI = resolve(),
        cardLinker: CardLinkerAPI = resolve(),
        kycRouter: PlatformUIKit.KYCRouting = resolve(),
        transactionsRouter: TransactionsRouterAPI = resolve(),
        topMostViewControllerProvider: TopMostViewControllerProviding = resolve(),
        alertViewPresenter: AlertViewPresenterAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        self.paymentMethodLinker = paymentMethodLinker
        self.bankWireLinker = bankWireLinker
        self.cardLinker = cardLinker
        self.kycRouter = kycRouter
        self.transactionsRouter = transactionsRouter
        self.topMostViewControllerProvider = topMostViewControllerProvider
        self.alertViewPresenter = alertViewPresenter
        self.featureFlagsService = featureFlagsService
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    func routeToConfirmation(transactionModel: TransactionModel) {
        let builder = ConfirmationPageBuilder(transactionModel: transactionModel)
        let router = builder.build(listener: interactor)
        let viewControllable = router.viewControllable
        attachChild(router)
        viewController.push(viewController: viewControllable)
    }

    func routeToInProgress(transactionModel: TransactionModel, action: AssetAction) {
        let builder = PendingTransactionPageBuilder()
        let router = builder.build(
            withListener: interactor,
            transactionModel: transactionModel,
            action: action
        )
        let viewControllable = router.viewControllable
        attachChild(router)
        viewController.push(viewController: viewControllable)
    }

    func closeFlow() {
        viewController.dismiss()
        interactor.listener?.dismissTransactionFlow()
    }

    func showFailure(error: Error) {
        Logger.shared.error(error)
        alertViewPresenter.error(in: viewController.uiviewController) { [weak self] in
            self?.closeFlow()
        }
    }

    func showErrorRecoverySuggestion(
        action: AssetAction,
        errorState: TransactionErrorState,
        transactionModel: TransactionModel,
        handleCalloutTapped: @escaping (ErrorRecoveryState.Callout) -> Void
    ) {
        // NOTE: this will be fixed in IOS-5576
        let view = ErrorRecoveryView(
            store: .init(
                initialState: ErrorRecoveryState(
                    title: errorState.recoveryWarningTitle(for: action),
                    message: errorState.recoveryWarningMessage(for: action),
                    callouts: errorState.recoveryWarningCallouts(for: action)
                ),
                reducer: errorRecoveryReducer,
                environment: ErrorRecoveryEnvironment(
                    close: {
                        transactionModel.process(action: .returnToPreviousStep)
                    },
                    calloutTapped: handleCalloutTapped
                )
            )
        )
        let viewController = UIHostingController(rootView: view)
        viewController.transitioningDelegate = bottomSheetPresenter
        viewController.modalPresentationStyle = .custom
        let presenter = topMostViewControllerProvider.topMostViewController
        presenter?.present(viewController, animated: true, completion: nil)
    }

    func pop() {
        viewController.pop()
    }

    func dismiss() {
        guard let topVC = topMostViewControllerProvider.topMostViewController else {
            return
        }
        let topRouter = children.last
        topVC.presentingViewController?.dismiss(animated: true) { [weak self] in
            // Detatch child in completion block to avoid false-positive leak checks
            guard let child = topRouter as? ViewableRouting, child.viewControllable.uiviewController === topVC else {
                return
            }
            self?.detachChild(child)
        }
    }

    func didTapBack() {
        guard let child = children.last else { return }
        pop()
        detachChild(child)
    }

    func routeToSourceAccountPicker(
        transitionType: TransitionType,
        transactionModel: TransactionModel,
        action: AssetAction,
        canAddMoreSources: Bool
    ) {
        let router = sourceAccountPickerRouter(
            with: transactionModel,
            action: action,
            canAddMoreSources: canAddMoreSources
        )
        attachAndPresent(router, transitionType: transitionType)
    }

    func routeToDestinationAccountPicker(
        transitionType: TransitionType,
        transactionModel: TransactionModel,
        action: AssetAction
    ) {
        let navigationModel: ScreenNavigationModel
        switch transitionType {
        case .push:
            navigationModel = ScreenNavigationModel.AccountPicker.navigationClose(
                title: TransactionFlowDescriptor.AccountPicker.destinationTitle(action: action)
            )
        case .modal, .replaceRoot:
            navigationModel = ScreenNavigationModel.AccountPicker.modal(
                title: TransactionFlowDescriptor.AccountPicker.destinationTitle(action: action)
            )
        }
        let router = destinationAccountPicker(
            with: transactionModel,
            navigationModel: navigationModel,
            action: action
        )
        attachAndPresent(router, transitionType: transitionType)
    }

    func routeToTargetSelectionPicker(transactionModel: TransactionModel, action: AssetAction) {
        let builder = TargetSelectionPageBuilder(
            accountProvider: TransactionModelAccountProvider(
                transactionModel: transactionModel,
                transform: { $0.availableTargets as? [BlockchainAccount] ?? [] }
            ),
            action: action
        )
        let router = builder.build(
            listener: .listener(interactor),
            navigationModel: ScreenNavigationModel.TargetSelection.navigation(
                title: TransactionFlowDescriptor.TargetSelection.navigationTitle(action: action)
            ),
            backButtonInterceptor: {
                transactionModel.state.map {
                    ($0.step, $0.stepsBackStack, $0.isGoingBack)
                }
            }
        )
        attachAndPresent(router, transitionType: .replaceRoot)
    }

    func presentLinkPaymentMethod(transactionModel: TransactionModel) {
        let presenter = viewController.uiviewController.topMostViewController ?? viewController.uiviewController
        paymentMethodLinker.presentAccountLinkingFlow(from: presenter) { [weak self] result in
            presenter.dismiss(animated: true) {
                guard let self = self else { return }
                switch result {
                case .abandoned:
                    transactionModel.process(action: .returnToPreviousStep)
                case .completed(let paymentMethod):
                    switch paymentMethod.type {
                    case .bankAccount:
                        transactionModel.process(action: .showBankWiringInstructions)
                    case .bankTransfer:
                        switch paymentMethod.fiatCurrency {
                        case .USD:
                            transactionModel.process(action: .showBankLinkingFlow)
                        case .GBP, .EUR:
                            self.featureFlagsService
                                .isEnabled(.remote(.openBanking))
                                .if(
                                    then: {
                                        transactionModel.process(action: .showBankLinkingFlow)
                                    },
                                    else: {
                                        transactionModel.process(action: .showBankWiringInstructions)
                                    }
                                )
                                .store(in: &self.cancellables)
                        default:
                            transactionModel.process(action: .showBankWiringInstructions)
                        }
                    case .card:
                        transactionModel.process(action: .showCardLinkingFlow)
                    case .funds:
                        transactionModel.process(action: .showBankWiringInstructions)
                    }
                }
            }
        }
    }

    func presentLinkACard(transactionModel: TransactionModel) {
        let presenter = viewController.uiviewController.topMostViewController ?? viewController.uiviewController
        cardLinker.presentCardLinkingFlow(from: presenter) { [transactionModel] result in
            presenter.dismiss(animated: true) {
                switch result {
                case .abandoned:
                    transactionModel.process(action: .returnToPreviousStep)
                case .completed:
                    transactionModel.process(action: .cardLinkingFlowCompleted)
                }
            }
        }
    }

    func presentLinkABank(transactionModel: TransactionModel) {
        let builder = LinkBankFlowRootBuilder()
        let router = builder.build()
        linkBankFlowRouter = router
        router.startFlow()
            .withLatestFrom(transactionModel.state) { ($0, $1) }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [topMostViewControllerProvider] effect, state in
                topMostViewControllerProvider
                    .topMostViewController?
                    .dismiss(animated: true, completion: nil)
                switch effect {
                case .closeFlow:
                    transactionModel.process(action: .bankLinkingFlowDismissed(state.action))
                case .bankLinked:
                    transactionModel.process(action: .bankAccountLinked(state.action))
                }
            })
            .disposed(by: disposeBag)
    }

    func presentBankWiringInstructions(transactionModel: TransactionModel) {
        let presenter = viewController.uiviewController.topMostViewController ?? viewController.uiviewController
        // NOTE: using [weak presenter] to avoid a memory leak
        bankWireLinker.present(from: presenter) { [weak presenter] in
            presenter?.dismiss(animated: true) {
                transactionModel.process(action: .returnToPreviousStep)
            }
        }
    }

    func presentOpenBanking(
        action: OpenBankingAction,
        transactionModel: TransactionModel,
        account: LinkedBankData
    ) {

        let presentingViewController = viewController.uiviewController.topMostViewController
            ?? viewController.uiviewController

        guard let presenter = presentingViewController as? TransactionFlowViewControllable else {
            fatalError(
                """
                Unable to present OpenBanking
                expected TransactionFlowViewControllable but got \(type(of: presentingViewController))
                """
            )
        }

        let environment = OpenBankingEnvironment(
            dismiss: { [weak presenter] in
                presenter?.dismiss()
            },
            cancel: { [weak presenter] in
                presenter?.pop()
            },
            currency: action.currency
        )

        let viewController: OpenBankingViewController
        switch action {
        case .buy(let order):
            viewController = OpenBankingViewController(
                order: .init(order),
                from: .init(account),
                environment: environment
            )
        case .deposit(let transaction):
            viewController = OpenBankingViewController(
                deposit: transaction.amount.minorString,
                product: "SIMPLEBUY",
                from: .init(account),
                environment: environment
            )
        }

        viewController.eventPublisher.sink { [weak presenter] result in
            switch result {
            case .success:
                transactionModel.process(action: .updateTransactionComplete)
                presenter?.dismiss()
            case .failure:
                break
            }
        }
        .store(withLifetimeOf: viewController)

        presenter.push(viewController: viewController)
    }

    func routeToPriceInput(
        source: BlockchainAccount,
        destination: TransactionTarget,
        transactionModel: TransactionModel,
        action: AssetAction
    ) {
        guard let source = source as? SingleAccount else { return }
        let builder = EnterAmountPageBuilder(transactionModel: transactionModel)
        let router = builder.build(
            listener: interactor,
            sourceAccount: source,
            destinationAccount: destination,
            action: action,
            navigationModel: ScreenNavigationModel.EnterAmount.navigation(
                allowsBackButton: action.allowsBackButton
            )
        )
        let viewControllable = router.viewControllable
        attachChild(router)
        if let childVC = viewController.uiviewController.children.first,
           childVC is TransactionFlowInitialViewController
        {
            viewController.replaceRoot(viewController: viewControllable, animated: false)
        } else {
            viewController.push(viewController: viewControllable)
        }
    }

    func presentKYCFlowIfNeeded(completion: @escaping (Bool) -> Void) {
        let presenter = topMostViewControllerProvider.topMostViewController ?? viewController.uiviewController
        interactor.listener?.presentKYCFlowIfNeeded(from: presenter, completion: completion)
    }

    func presentKYCUpgradeFlow(completion: @escaping (Bool) -> Void) {
        let presenter = topMostViewControllerProvider.topMostViewController ?? viewController.uiviewController
        kycRouter
            .presentKYCUpgradeFlow(from: presenter)
            .map { result -> Bool in result == .completed }
            .sink(receiveValue: completion)
            .store(in: &cancellables)
    }

    func routeToSecurityChecks(transactionModel: TransactionModel) {
        let presenter = topMostViewControllerProvider.topMostViewController ?? viewController.uiviewController
        securityRouter = PaymentSecurityRouter { result in
            Logger.shared.debug(String(describing: result))
            switch result {
            case .abandoned, .failed:
                transactionModel.process(action: .returnToPreviousStep)
            case .pending, .completed:
                transactionModel.process(action: .securityChecksCompleted)
            }
        }
        transactionModel
            .state
            .take(1)
            .asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe { [securityRouter, showFailure] transactionState in
                guard
                    let order = transactionState.order as? OrderDetails,
                    let authorizationData = order.authorizationData
                else {
                    let error = FatalTransactionError.message("Order should contain authorization data.")
                    showFailure(error)
                    return
                }
                securityRouter?.presentPaymentSecurity(
                    from: presenter,
                    authorizationData: authorizationData
                )
            } onError: { [showFailure] error in
                showFailure(error)
            }
            .disposed(by: disposeBag)
    }

    func presentNewTransactionFlow(
        to action: TransactionFlowAction,
        completion: @escaping (Bool) -> Void
    ) {
        let presenter = topMostViewControllerProvider.topMostViewController ?? viewController.uiviewController
        transactionsRouter
            .presentTransactionFlow(to: action, from: presenter)
            .map { $0 == .completed }
            .sink(receiveValue: completion)
            .store(in: &cancellables)
    }
}

extension TransactionFlowRouter {

    private func present(_ viewControllerToPresent: UIViewController, transitionType: TransitionType) {
        switch transitionType {
        case .modal:
            viewController.present(viewController: viewControllerToPresent, animated: true)
        case .push:
            viewController.push(viewController: viewControllerToPresent)
        case .replaceRoot:
            viewController.replaceRoot(viewController: viewControllerToPresent, animated: false)
        }
    }

    private func attachAndPresent(_ router: ViewableRouting, transitionType: TransitionType) {
        attachChild(router)
        present(router.viewControllable.uiviewController, transitionType: transitionType)
    }
}

extension TransactionFlowRouter {

    private func sourceAccountPickerRouter(
        with transactionModel: TransactionModel,
        action: AssetAction,
        canAddMoreSources: Bool
    ) -> AccountPickerRouting {
        let subtitle = TransactionFlowDescriptor.AccountPicker.sourceSubtitle(action: action)
        let builder = AccountPickerBuilder(
            accountProvider: TransactionModelAccountProvider(
                transactionModel: transactionModel,
                transform: { $0.availableSources }
            ),
            action: action
        )
        let shouldAddMoreButton = canAddMoreSources && action.supportsAddingSourceAccounts
        let button: ButtonViewModel? = shouldAddMoreButton ? .secondary(with: LocalizationConstants.addNew) : nil
        return builder.build(
            listener: .listener(interactor),
            navigationModel: ScreenNavigationModel.AccountPicker.modal(
                title: TransactionFlowDescriptor.AccountPicker.sourceTitle(action: action)
            ),
            headerModel: subtitle.isEmpty ? .none : .simple(AccountPickerSimpleHeaderModel(subtitle: subtitle)),
            buttonViewModel: button
        )
    }

    private func destinationAccountPicker(
        with transactionModel: TransactionModel,
        navigationModel: ScreenNavigationModel,
        action: AssetAction
    ) -> AccountPickerRouting {
        let subtitle = TransactionFlowDescriptor.AccountPicker.destinationSubtitle(action: action)
        let builder = AccountPickerBuilder(
            accountProvider: TransactionModelAccountProvider(
                transactionModel: transactionModel,
                transform: {
                    $0.availableTargets as? [BlockchainAccount] ?? []
                }
            ),
            action: action
        )
        let button: ButtonViewModel? = action == .withdraw ? .secondary(with: LocalizationConstants.addNew) : nil
        return builder.build(
            listener: .listener(interactor),
            navigationModel: navigationModel,
            headerModel: subtitle.isEmpty ? .none : .simple(AccountPickerSimpleHeaderModel(subtitle: subtitle)),
            buttonViewModel: button
        )
    }
}

extension AssetAction {

    var supportsAddingSourceAccounts: Bool {
        switch self {
        case .buy,
             .deposit:
            return true

        case .sell,
             .withdraw,
             .receive,
             .send,
             .sign,
             .swap,
             .viewActivity,
             .interestWithdraw,
             .interestTransfer:
            return false
        }
    }
}
