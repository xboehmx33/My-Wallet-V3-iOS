// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import PlatformKit
import PlatformUIKit
import RIBs
import RxRelay
import RxSwift
import ToolKit

enum TransitionType: Equatable {
    case push
    case modal
    case replaceRoot
}

enum OpenBankingAction {
    case buy(OrderDetails)
    case deposit(PendingTransaction)
}

protocol TransactionFlowRouting: Routing {

    var isDisplayingRootViewController: Bool { get }

    /// Pop the current screen off the stack.
    func pop()

    /// Dismiss the top most screen. Currently not called but should be used when
    /// a picker is presented over the `Enter Amount` screen. This is different from
    /// going back.
    func dismiss()

    /// Exit the flow. This occurs usually when the user taps the close button
    /// on the top right of the screen.
    func closeFlow()

    /// The back button was tapped.
    func didTapBack()

    /// Show the failure screen. Sometimes an error is thrown when selecting an
    /// account or entering in transaction details. If this error occurs, we should
    /// show a failure screen.
    func showFailure(error: Error)

    /// Presents a modal with information  about the transaction error state and, if needed, a call to action for the user to resolve that error state.
    func showErrorRecoverySuggestion(
        action: AssetAction,
        errorState: TransactionErrorState,
        transactionModel: TransactionModel,
        handleCalloutTapped: @escaping (ErrorRecoveryState.Callout) -> Void
    )

    /// Show the `source` selection screen. This replaces the root.
    func routeToSourceAccountPicker(
        transitionType: TransitionType,
        transactionModel: TransactionModel,
        action: AssetAction,
        canAddMoreSources: Bool
    )

    /// Show the target selection screen (currently only used in `Send`).
    /// This pushes onto the prior screen.
    func routeToTargetSelectionPicker(transactionModel: TransactionModel, action: AssetAction)

    /// Route to the destination account picker from the target selection screen
    func routeToDestinationAccountPicker(
        transitionType: TransitionType,
        transactionModel: TransactionModel,
        action: AssetAction
    )

    /// Present the payment method linking flow modally over the current screen
    func presentLinkPaymentMethod(transactionModel: TransactionModel)

    /// Present the card linking flow modally over the current screen
    func presentLinkACard(transactionModel: TransactionModel)

    /// Present the bank linking flow modally over the current screen
    func presentLinkABank(transactionModel: TransactionModel)

    /// Present wiring instructions so users can deposit funds into their wallet
    func presentBankWiringInstructions(transactionModel: TransactionModel)

    /// Present open banking authorisation so users can deposit funds into their wallet
    func presentOpenBanking(
        action: OpenBankingAction,
        transactionModel: TransactionModel,
        account: LinkedBankData
    )

    /// Route to the in progress screen. This pushes onto the navigation stack.
    func routeToInProgress(transactionModel: TransactionModel, action: AssetAction)

    /// Route to the transaction security checks screen (e.g. 3DS checks for card payments)
    func routeToSecurityChecks(transactionModel: TransactionModel)

    /// Show the `EnterAmount` screen. This pushes onto the prior screen.
    /// For `Buy` we should set this as the root.
    func routeToPriceInput(
        source: BlockchainAccount,
        destination: TransactionTarget,
        transactionModel: TransactionModel,
        action: AssetAction
    )

    /// Show the confirmation screen. This pushes onto the prior screen.
    func routeToConfirmation(transactionModel: TransactionModel)

    /// Presents the KYC Flow if needed or progresses the transactionModel to the next step otherwise
    func presentKYCFlowIfNeeded(completion: @escaping (Bool) -> Void)

    /// Presents the KYC Upgrade Flow.
    /// - Parameters:
    ///  - completion: A closure that is called with `true` if the user completed the KYC flow to move to the next tier.
    func presentKYCUpgradeFlow(completion: @escaping (Bool) -> Void)

    /// Presentes a new transaction flow on top of the current one
    func presentNewTransactionFlow(
        to action: TransactionFlowAction,
        completion: @escaping (Bool) -> Void
    )
}

public protocol TransactionFlowListener: AnyObject {
    func presentKYCFlowIfNeeded(from viewController: UIViewController, completion: @escaping (Bool) -> Void)
    func dismissTransactionFlow()
}

// swiftlint:disable type_body_length
final class TransactionFlowInteractor: PresentableInteractor<TransactionFlowPresentable>,
    TransactionFlowInteractable,
    AccountPickerListener,
    TransactionFlowPresentableListener,
    TargetSelectionPageListener
{

    weak var router: TransactionFlowRouting?
    weak var listener: TransactionFlowListener?

    private var initialStep: Bool = true
    private let transactionModel: TransactionModel
    private let action: AssetAction // TODO: this should be removed and taken from TransactionModel
    private let sourceAccount: BlockchainAccount? // TODO: this should be removed and taken from TransactionModel
    private let target: TransactionTarget? // TODO: this should be removed and taken from TransactionModel
    private let analyticsHook: TransactionAnalyticsHook

    init(
        transactionModel: TransactionModel,
        action: AssetAction,
        sourceAccount: BlockchainAccount?,
        target: TransactionTarget?,
        presenter: TransactionFlowPresentable,
        analyticsHook: TransactionAnalyticsHook = resolve()
    ) {
        self.transactionModel = transactionModel
        self.action = action
        self.sourceAccount = sourceAccount
        self.target = target
        self.analyticsHook = analyticsHook
        super.init(presenter: presenter)
        presenter.listener = self
    }

    deinit {
        transactionModel.destroy()
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        transactionModel
            .state
            .distinctUntilChanged(\.step)
            .withPrevious()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe { [weak self] previousState, newState in
                self?.handleStateChange(previousState: previousState, newState: newState)
            }
            .disposeOnDeactivate(interactor: self)

        let requireSecondPassword: Single<Bool> = sourceAccount?.requireSecondPassword ?? .just(false)

        requireSecondPassword
            .observeOn(MainScheduler.asyncInstance)
            .map { [sourceAccount, target, action] passwordRequired -> TransactionAction in
                switch action {
                case .deposit:
                    return self.handleFiatDeposit(
                        sourceAccount: sourceAccount,
                        target: target,
                        passwordRequired: passwordRequired
                    )

                case .swap where sourceAccount != nil && target != nil:
                    return .initialiseWithSourceAndPreferredTarget(
                        action: action,
                        sourceAccount: sourceAccount!,
                        target: target!,
                        passwordRequired: passwordRequired
                    )

                case _ where sourceAccount != nil && target != nil:
                    return .initialiseWithSourceAndTargetAccount(
                        action: action,
                        sourceAccount: sourceAccount!,
                        target: target!,
                        passwordRequired: passwordRequired
                    )

                case _ where sourceAccount != nil:
                    return .initialiseWithSourceAccount(
                        action: action,
                        sourceAccount: sourceAccount!,
                        passwordRequired: passwordRequired
                    )

                case _ where target != nil:
                    return .initialiseWithTargetAndNoSource(
                        action: action,
                        target: target!,
                        passwordRequired: passwordRequired
                    )

                default:
                    return .initialiseWithNoSourceOrTargetAccount(
                        action: action,
                        passwordRequired: passwordRequired
                    )
                }
            }
            .subscribe(
                onSuccess: { [weak self] action in
                    self?.transactionModel.process(action: action)
                },
                onError: { [weak self] error in
                    Logger.shared.debug("Unable to configure transaction flow, aborting. \(String(describing: error))")
                    self?.finishFlow()
                }
            )
            .disposeOnDeactivate(interactor: self)
    }

    override func willResignActive() {
        super.willResignActive()
    }

    func didSelectActionButton() {
        transactionModel.process(action: .showAddAccountFlow)
    }

    func didSelect(blockchainAccount: BlockchainAccount) {
        guard let target = blockchainAccount as? TransactionTarget else {
            fatalError("Account \(blockchainAccount.self) is not currently supported.")
        }
        didSelect(target: target)
    }

    func didSelect(target: TransactionTarget) {
        transactionModel.state
            .take(1)
            .asSingle()
            .subscribe(onSuccess: { [weak self] state in
                switch state.step {
                case .selectSource:
                    /// Apply the source account
                    self?.didSelectSourceAccount(account: target as! BlockchainAccount)
                    /// If the flow was started with a destination already, like if they
                    /// are depositing into a `FiatAccount`, we apply the destination.
                    /// This will route the user to the `Enter Amount` screen.
                    if let destination = state.destination {
                        self?.didSelectDestinationAccount(target: destination)
                    }
                case .selectTarget:
                    self?.didSelectDestinationAccount(target: target)
                    if let selectedSource = state.source as? CryptoAccount,
                       let target = target as? CryptoAccount
                    {
                        self?.analyticsHook.onReceiveAccountSelected(
                            selectedSource,
                            target: target,
                            action: state.action
                        )
                    }

                default:
                    break
                }
            })
            .disposeOnDeactivate(interactor: self)
    }

    func didTapBack() {
        transactionModel.process(action: .returnToPreviousStep)
    }

    func didTapClose() {
        guard router?.isDisplayingRootViewController == true else {
            // there's a modal to dismiss
            transactionModel.process(action: .returnToPreviousStep)
            return
        }
        // the top most view controller is at the root of the flow, so dismissing it means closing the flow itself.
        router?.closeFlow()
        analyticsHook.onClose(action: action)
    }

    func enterAmountDidTapBack() {
        transactionModel.process(action: .returnToPreviousStep)
    }

    func closeFlow() {
        transactionModel.process(action: .resetFlow)
        router?.closeFlow()
        analyticsHook.onClose(action: action)
    }

    func showKYCUpgradePrompt() {
        router?.presentKYCUpgradeFlow { [weak self] didUpgrade in
            if didUpgrade {
                self?.closeFlow()
            }
        }
    }

    func checkoutDidTapBack() {
        transactionModel.process(action: .returnToPreviousStep)
    }

    func didSelectSourceAccount(account: BlockchainAccount) {
        analyticsHook.onFromAccountSelected(account, action: action)
        transactionModel.process(action: .sourceAccountSelected(account))
    }

    func didSelectDestinationAccount(target: TransactionTarget) {
        transactionModel.process(action: .targetAccountSelected(target))
    }

    func didConfirmTransaction() {
        transactionModel.process(action: .executeTransaction)
    }

    func continueToKYCTiersScreen() {
        router?.presentKYCFlowIfNeeded { _ in
            // NOOP: this was designed for Swap where presenting KYC means replacing the root view with a KYC prompt.
            // This completion block is never called.
        }
    }

    func showGenericFailure(error: Error) {
        router?.showFailure(error: error)
    }

    // MARK: - Private Functions

    private func doCloseFlow() {
        router?.closeFlow()
        analyticsHook.onClose(action: action)
    }

    private func handleStateChange(previousState: TransactionState?, newState: TransactionState) {
        if !initialStep, newState.step == .initial {
            finishFlow()
        } else {
            initialStep = newState.step == .initial
            showFlowStep(previousState: previousState, newState: newState)
            analyticsHook.onStepChanged(newState)
        }
    }

    private func finishFlow() {
        transactionModel.process(action: .resetFlow)
    }

    // swiftlint:disable cyclomatic_complexity
    private func showFlowStep(previousState: TransactionState?, newState: TransactionState) {
        guard previousState?.step != newState.step else {
            // if the step hasn't changed we have nothing to do
            return
        }
        guard !newState.isGoingBack else {
            guard previousState?.step.goingBackSkipsNavigation == false else {
                return
            }

            if router?.isDisplayingRootViewController == false {
                router?.dismiss()
            } else {
                router?.didTapBack()
            }
            return
        }

        switch newState.step {
        case .initial:
            break

        case .authorizeOpenBanking:

            let linkedBankData: LinkedBankData
            switch previousState?.source {
            case let account as PaymentMethodAccount:
                switch account.paymentMethodType {
                case .linkedBank(let data):
                    linkedBankData = data
                default:
                    return assertionFailure("Authorising open banking without a valid payment method")
                }
            case let account as LinkedBankAccount:
                linkedBankData = account.data
            default:
                return assertionFailure("Authorising open banking without a valid account type")
            }

            switch previousState?.action {
            case .buy:
                guard let order = previousState?.order as? OrderDetails else {
                    return assertionFailure("OpenBanking for buy requires OrderDetails")
                }
                router?.presentOpenBanking(
                    action: .buy(order),
                    transactionModel: transactionModel,
                    account: linkedBankData
                )
            case .deposit:
                guard let order = previousState?.pendingTransaction else {
                    return assertionFailure("OpenBanking for deposit requires a PendingTransaction")
                }
                router?.presentOpenBanking(
                    action: .deposit(order),
                    transactionModel: transactionModel,
                    account: linkedBankData
                )
            default:
                return assertionFailure("OpenBanking authorisation is only required for buy and deposit")
            }

        case .enterAmount:
            router?.routeToPriceInput(
                source: newState.source!,
                destination: newState.destination!,
                transactionModel: transactionModel,
                action: action
            )

        case .linkPaymentMethod:
            router?.presentLinkPaymentMethod(transactionModel: transactionModel)

        case .linkACard:
            router?.presentLinkACard(transactionModel: transactionModel)

        case .linkABank:
            router?.presentLinkABank(transactionModel: transactionModel)

        case .linkBankViaWire:
            router?.presentBankWiringInstructions(transactionModel: transactionModel)

        case .enterPassword:
            unimplemented()

        case .selectTarget:
            /// `TargetSelectionViewController` should only be shown for `SendP2`
            /// and `.send`. Otherwise we should show the account picker to select
            /// the destination/target.
            switch action {
            case .send:
                // `Send` supports the target selection screen rather than a
                // destination selection screen.
                router?.routeToTargetSelectionPicker(
                    transactionModel: transactionModel,
                    action: action
                )
            case .buy:
                router?.routeToDestinationAccountPicker(
                    transitionType: newState.stepsBackStack.contains(.enterAmount) ? .modal : .replaceRoot,
                    transactionModel: transactionModel,
                    action: action
                )
            case .withdraw,
                 .interestWithdraw:
                // `Withdraw` shows the destination screen modally. It does not
                // present over another screen (and thus replaces the root).
                router?.routeToDestinationAccountPicker(
                    transitionType: .replaceRoot,
                    transactionModel: transactionModel,
                    action: action
                )
            case .deposit,
                 .interestTransfer,
                 .sell,
                 .swap:
                router?.routeToDestinationAccountPicker(
                    transitionType: newState.stepsBackStack.contains(.selectSource) ? .push : .replaceRoot,
                    transactionModel: transactionModel,
                    action: action
                )
            case .receive,
                 .sign,
                 .viewActivity:
                unimplemented("Action \(action) does not support 'selectTarget'")
            }

        case .kycChecks:
            router?.presentKYCFlowIfNeeded { [transactionModel] didCompleteKYC in
                if didCompleteKYC {
                    transactionModel.process(action: .validateTransactionAfterKYC)
                } else {
                    transactionModel.process(action: .returnToPreviousStep)
                }
            }

        case .validateSource:
            switch action {
            case .buy:
                linkPaymentMethodOrMoveToNextStep(for: newState)
            default:
                // there's no need to validate the source account for these kinds of transactions
                transactionModel.process(action: .prepareTransaction)
            }

        case .confirmDetail:
            router?.routeToConfirmation(transactionModel: transactionModel)

        case .inProgress:
            router?.routeToInProgress(
                transactionModel: transactionModel,
                action: action
            )

        case .selectSource:
            let canAddMoreSources = newState.userKYCStatus?.tiers.isTier2Approved ?? false
            switch action {
            case .buy where newState.stepsBackStack.contains(.enterAmount):
                router?.routeToSourceAccountPicker(
                    transitionType: .modal,
                    transactionModel: transactionModel,
                    action: action,
                    canAddMoreSources: canAddMoreSources
                )

            case .deposit,
                 .interestTransfer,
                 .withdraw,
                 .buy,
                 .interestWithdraw,
                 .sell,
                 .swap,
                 .send,
                 .receive,
                 .viewActivity:
                router?.routeToSourceAccountPicker(
                    transitionType: .replaceRoot,
                    transactionModel: transactionModel,
                    action: action,
                    canAddMoreSources: canAddMoreSources
                )
            case .sign:
                unimplemented("Sign action does not support selectSource.")
            }

        case .enterAddress:
            router?.routeToDestinationAccountPicker(
                transitionType: action == .buy ? .replaceRoot : .push,
                transactionModel: transactionModel,
                action: action
            )

        case .securityConfirmation:
            router?.routeToSecurityChecks(
                transactionModel: transactionModel
            )

        case .errorRecoveryInfo:
            router?.showErrorRecoverySuggestion(
                action: newState.action,
                errorState: newState.errorState,
                transactionModel: transactionModel,
                handleCalloutTapped: { [weak self] callout in
                    self?.handleCalloutTapped(callout: callout, state: newState)
                }
            )

        case .closed:
            transactionModel.destroy()
        }
    }

    private func handleFiatDeposit(
        sourceAccount: BlockchainAccount?,
        target: TransactionTarget?,
        passwordRequired: Bool
    ) -> TransactionAction {
        if let source = sourceAccount, let target = target {
            return .initialiseWithSourceAndTargetAccount(
                action: .deposit,
                sourceAccount: source,
                target: target,
                passwordRequired: passwordRequired
            )
        }
        if let source = sourceAccount {
            return .initialiseWithSourceAccount(
                action: .deposit,
                sourceAccount: source,
                passwordRequired: passwordRequired
            )
        }
        if let target = target {
            return .initialiseWithTargetAndNoSource(
                action: .deposit,
                target: target,
                passwordRequired: passwordRequired
            )
        }
        return .initialiseWithNoSourceOrTargetAccount(
            action: .deposit,
            passwordRequired: passwordRequired
        )
    }

    private func handleCalloutTapped(callout: ErrorRecoveryState.Callout, state: TransactionState) {
        switch callout.id {
        case AnyHashable(ErrorRecoveryCalloutIdentifier.upgradeKYCTier.rawValue):
            router?.presentKYCUpgradeFlow { _ in }
        case AnyHashable(ErrorRecoveryCalloutIdentifier.buy.rawValue):
            guard let account = state.source as? CryptoAccount else {
                return
            }
            router?.presentNewTransactionFlow(to: .buy(account)) { _ in }
        default:
            unimplemented()
        }
    }

    private func linkPaymentMethodOrMoveToNextStep(for transactionState: TransactionState) {
        guard let paymentAccount = transactionState.source as? PaymentMethodAccount else {
            impossible("The source account for Buy should be a valid payment method")
        }
        // If the select payment account's method is a suggested payment method, it means we need to link a bank or card to the user's account.
        // Otherwise, we can move on to the order details confirmation screen as we're able to process the transaction.
        guard case .suggested = paymentAccount.paymentMethodType else {
            transactionModel.process(action: .prepareTransaction)
            return
        }
        // Otherwise, make the user link a relevant payment account.
        switch paymentAccount.paymentMethod.type {
        case .bankAccount:
            transactionModel.process(action: .showBankWiringInstructions)
        case .bankTransfer:
            // Check the currency to ensure the user can link a bank via ACH until Open Banking is complete.
            if paymentAccount.paymentMethod.fiatCurrency == .USD {
                transactionModel.process(action: .showBankLinkingFlow)
            } else {
                transactionModel.process(action: .showBankWiringInstructions)
            }
        case .card:
            transactionModel.process(action: .showCardLinkingFlow)
        case .funds:
            // Nothing to link, move on to the next step
            transactionModel.process(action: .prepareTransaction)
        }
    }
}

extension OpenBankingAction {

    var currency: String {
        switch self {
        case .buy(let order):
            return order.inputValue.code
        case .deposit(let order):
            return order.amount.code
        }
    }
}
