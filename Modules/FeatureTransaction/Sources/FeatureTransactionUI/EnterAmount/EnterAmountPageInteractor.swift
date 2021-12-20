// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureTransactionDomain
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RIBs
import RxCocoa
import RxSwift
import ToolKit

protocol EnterAmountPageRouting: AnyObject {
    func showFeeSelectionSheet(with transactionModel: TransactionModel)
    func showError(_ error: Error)
}

protocol EnterAmountPageListener: AnyObject {
    func enterAmountDidTapBack()
    func closeFlow()
    func continueToKYCTiersScreen()
    func showGenericFailure(error: Error)
}

protocol EnterAmountPagePresentable: Presentable {

    var continueButtonTapped: Signal<Void> { get }

    func presentWithdrawalLocks(amountAvailable: String)

    func connect(
        state: Driver<EnterAmountPageInteractor.State>
    ) -> Driver<EnterAmountPageInteractor.NavigationEffects>
}

protocol AuxiliaryViewPresenting: AnyObject {

    func makeViewController() -> UIViewController
}

protocol AuxiliaryViewPresentingDelegate: AnyObject {

    func auxiliaryViewTapped(_ presenter: AuxiliaryViewPresenting, state: TransactionState)
}

final class EnterAmountPageInteractor: PresentableInteractor<EnterAmountPagePresentable>, EnterAmountPageInteractable {

    weak var router: EnterAmountPageRouting?
    weak var listener: EnterAmountPageListener?

    private var topAuxiliaryViewPresenter: AuxiliaryViewPresenting?

    /// The interactor that `SendAuxiliaryViewPresenter` uses
    private let sendAuxiliaryViewInteractor: SendAuxiliaryViewInteractor
    private let sendAuxiliaryViewPresenter: SendAuxiliaryViewPresenter

    private let accountAuxiliaryViewInteractor: AccountAuxiliaryViewInteractor
    private let accountAuxiliaryViewPresenter: AccountAuxiliaryViewPresenter

    /// The interactor that `SingleAmountPreseneter` uses
    private let amountViewInteractor: AmountViewInteracting

    private let transactionModel: TransactionModel
    private let action: AssetAction
    private let navigationModel: ScreenNavigationModel

    private let featureFlagService: FeatureFlagsServiceAPI
    private let analyticsHook: TransactionAnalyticsHook
    private let eventsRecorder: Recording

    init(
        transactionModel: TransactionModel,
        presenter: EnterAmountPagePresentable,
        amountInteractor: AmountViewInteracting,
        action: AssetAction,
        navigationModel: ScreenNavigationModel,
        featureFlagsService: FeatureFlagsServiceAPI = resolve(),
        analyticsHook: TransactionAnalyticsHook = resolve(),
        eventsRecorder: Recording = resolve(tag: "CrashlyticsRecorder")
    ) {
        self.action = action
        self.transactionModel = transactionModel
        amountViewInteractor = amountInteractor
        self.navigationModel = navigationModel
        featureFlagService = featureFlagsService
        self.analyticsHook = analyticsHook
        self.eventsRecorder = eventsRecorder
        sendAuxiliaryViewInteractor = SendAuxiliaryViewInteractor()
        sendAuxiliaryViewPresenter = SendAuxiliaryViewPresenter(
            interactor: sendAuxiliaryViewInteractor
        )
        accountAuxiliaryViewInteractor = AccountAuxiliaryViewInteractor()
        accountAuxiliaryViewPresenter = AccountAuxiliaryViewPresenter(
            interactor: accountAuxiliaryViewInteractor
        )
        super.init(presenter: presenter)
    }

    // TODO: Clean up this function
    // swiftlint:disable function_body_length
    // swiftlint:disable cyclomatic_complexity
    override func didBecomeActive() {
        super.didBecomeActive()

        let transactionState: Observable<TransactionState> = transactionModel
            .state
            .share(replay: 1, scope: .whileConnected)

        // THIS IS NO AMOUNT CONVERSION. NAME IS CONFUSING.
        amountViewInteractor
            .effect
            .subscribe { [weak self] effect in
                self?.handleAmountTranslation(effect: effect)
            }
            .disposeOnDeactivate(interactor: self)

        disableAmountViewBadgeIfNeeded()

        amountViewInteractor
            .amount
            .debounce(.milliseconds(250), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .distinctUntilChanged()
            .flatMap { amount -> Observable<MoneyValue> in
                transactionState
                    .take(1)
                    .asSingle()
                    .map { state in
                        if let fiatValue = amount.fiatValue, !state.allowFiatInput {
                            // Fiat Input but state does not allow fiat
                            guard let sourceToFiatPair = state.sourceToFiatPair else {
                                return .zero(currency: state.asset)
                            }
                            return MoneyValuePair(
                                fiatValue: fiatValue,
                                exchangeRate: sourceToFiatPair.quote.fiatValue!,
                                cryptoCurrency: state.asset.cryptoCurrency!,
                                usesFiatAsBase: true
                            ).quote
                        }
                        return amount
                    }
                    .asObservable()
            }
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe { [weak self] (amount: MoneyValue) in
                self?.transactionModel.process(action: .updateAmount(amount))
            }
            .disposeOnDeactivate(interactor: self)

        let spendable = Observable
            .combineLatest(
                transactionState,
                amountViewInteractor.activeInput
            )
            .map { state, input in
                (
                    min: state.minSpendable.displayableRounding(roundingMode: .up),
                    max: state.maxSpendable.displayableRounding(roundingMode: .down),
                    errorState: state.errorState,
                    exchangeRate: state.sourceToFiatPair,
                    activeInput: input,
                    amount: state.amount
                )
            }
            .share(scope: .whileConnected)

        transactionState
            .distinctUntilChanged(\.feeSelection, comparer: { $0 == $1 })
            .filter { $0.feeSelection.selectedLevel != .none }
            .subscribe(onNext: { [analyticsHook] state in
                analyticsHook.onFeeSelected(state: state)
            })
            .disposeOnDeactivate(interactor: self)

        amountViewInteractor.maxAmountSelected
            .withLatestFrom(transactionState)
            .subscribe(onNext: analyticsHook.onMinSelected(state:))
            .disposeOnDeactivate(interactor: self)

        amountViewInteractor.minAmountSelected
            .withLatestFrom(transactionState)
            .subscribe(onNext: analyticsHook.onMinSelected(state:))
            .disposeOnDeactivate(interactor: self)

        let fee = transactionState
            .takeWhile { $0.action == .send }
            .compactMap(\.pendingTransaction)
            .map(\.feeAmount)
            .share(scope: .whileConnected)

        let auxiliaryViewAccount = transactionState
            .takeWhile { $0.action.supportsBottomAccountsView }
            .map { state -> BlockchainAccount? in
                switch state.action {
                case .buy,
                     .deposit,
                     .interestTransfer:
                    return state.source
                case .sell,
                     .withdraw,
                     .interestWithdraw:
                    return state.destination as? BlockchainAccount
                case .viewActivity,
                     .send,
                     .sign,
                     .receive,
                     .swap:
                    fatalError("Unsupported action")
                }
            }
            .compactMap { $0 }
            .share(scope: .whileConnected)

        let availableSources = transactionState
            .map(\.availableSources)
            .share(scope: .whileConnected)

        let availableTargets = transactionState
            .map(\.availableTargets)
            .share(scope: .whileConnected)

        let bottomAuxiliaryAccounts = Observable
            .zip(
                availableSources,
                availableTargets
            )
            .map { [action] availableSources, availableTargets -> [Account] in
                guard action == .buy || action == .deposit else {
                    return availableTargets
                }
                return availableSources
            }

        let userKYCTier = transactionState
            .map(\.userKYCStatus)
            .map(\.?.tiers.latestApprovedTier)
            .share(scope: .whileConnected)

        let bottomAuxiliaryViewEnabled = Observable
            .combineLatest(
                userKYCTier,
                bottomAuxiliaryAccounts
            )
            .map { [action] userKYCTier, accounts -> Bool in
                guard let userKYCTier = userKYCTier, action == .buy && userKYCTier < .tier2 else {
                    return !accounts.isEmpty
                }
                // SDD eligible users cannot add more than 1 payment method so they should have no suggested accounts they can link.
                // Non-SDD eligible users will have a set of suggested accounts they can link, so the button should be enabled.
                let suggestedPaymentMethods: [Account] = accounts
                    .compactMap { $0 as? PaymentMethodAccount }
                    .filter(\.paymentMethodType.isSuggested)
                // Checking for accounts > 1 just in case we allowed some SDD users to add more than 1 payment methods
                return accounts.count > 1 || suggestedPaymentMethods.count > 1
            }

        accountAuxiliaryViewInteractor
            .connect(
                stream: auxiliaryViewAccount,
                tapEnabled: bottomAuxiliaryViewEnabled
            )
            .disposeOnDeactivate(interactor: self)

        accountAuxiliaryViewInteractor
            .auxiliaryViewTapped
            .withLatestFrom(transactionState)
            .subscribe(onNext: { [weak self] state in
                self?.handleBottomAuxiliaryViewTapped(state: state)
            })
            .disposeOnDeactivate(interactor: self)

        sendAuxiliaryViewInteractor
            .connect(fee: fee)
            .disposeOnDeactivate(interactor: self)

        sendAuxiliaryViewInteractor
            .connect(stream: spendable.map(\.max))
            .disposeOnDeactivate(interactor: self)

        sendAuxiliaryViewInteractor
            .resetToMaxAmount
            .withLatestFrom(spendable.map(\.max))
            .subscribe(onNext: { [weak self] maxSpendable in
                self?.amountViewInteractor.set(amount: maxSpendable)
            })
            .disposeOnDeactivate(interactor: self)

        sendAuxiliaryViewInteractor
            .resetToMaxAmount
            .withLatestFrom(transactionState)
            .subscribe(onNext: { [analyticsHook] state in
                analyticsHook.onMaxSelected(state: state)
            })
            .disposeOnDeactivate(interactor: self)

        sendAuxiliaryViewInteractor
            .availableBalanceTapped
            .withLatestFrom(spendable.map(\.max))
            .subscribe(onNext: { [weak self] maxSpendable in
                self?.amountViewInteractor.set(amount: maxSpendable)
            })
            .disposeOnDeactivate(interactor: self)

        sendAuxiliaryViewInteractor
            .networkFeeTapped
            .bindAndCatch(weak: self) { (self, _) in
                self.router?.showFeeSelectionSheet(with: self.transactionModel)
            }
            .disposeOnDeactivate(interactor: self)

        spendable
            .map { [weak listener] spendable in
                spendable.errorState.toAmountInteractorState(
                    min: spendable.min,
                    max: spendable.max,
                    exchangeRate: spendable.exchangeRate,
                    activeInput: spendable.activeInput,
                    stateAmount: spendable.amount,
                    listener: listener
                )
            }
            .bindAndCatch(to: amountViewInteractor.stateRelay)
            .disposeOnDeactivate(interactor: self)

        let transactionStateAndLimitsFeature: Observable<(TransactionState, Bool)> = Observable
            .combineLatest(
                transactionState,
                featureFlagService
                    .isEnabled(.remote(.newLimitsUIEnabled))
                    .asObservable()
            )

        let interactorState = transactionStateAndLimitsFeature
            .subscribeOn(MainScheduler.asyncInstance)
            .scan(initialState()) { [weak self] currentState, tuple -> State in
                let (updater, newLimitsUIEnabled) = tuple
                guard let self = self else {
                    return currentState
                }
                let newState = self.calculateNextState(
                    with: currentState,
                    updater: updater
                )
                // NOTE: temporary overrides to check for the feature flag's value
                return newState
                    .update(\.showContinueAction, value: !newLimitsUIEnabled || newState.showContinueAction)
                    .update(\.showErrorRecoveryAction, value: newLimitsUIEnabled && newState.showErrorRecoveryAction)
            }
            .asDriverCatchError()

        presenter
            .continueButtonTapped
            .asObservable()
            .withLatestFrom(transactionState)
            .subscribe(onNext: { [transactionModel, analyticsHook] state in
                switch state.action {
                case .buy:
                    if state.userKYCStatus?.canPurchaseCrypto == true {
                        transactionModel.process(action: .validateSourceAccount)
                    } else {
                        transactionModel.process(action: .performKYCChecks)
                    }
                default:
                    transactionModel.process(action: .prepareTransaction)
                }
                analyticsHook.onEnterAmountContinue(with: state)
            })
            .disposeOnDeactivate(interactor: self)

        presenter
            .connect(state: interactorState)
            .drive(onNext: handle(effects:))
            .disposeOnDeactivate(interactor: self)

        transactionState
            .compactMap { state -> (action: AssetAction, amountIsZero: Bool, networkFeeAdjustmentSupported: Bool)? in
                guard let pendingTransaction = state.pendingTransaction else {
                    return nil
                }
                return (
                    state.action,
                    state.amount.isZero,
                    pendingTransaction.availableFeeLevels.networkFeeAdjustmentSupported
                )
            }
            .map { action, amountIsZero, networkFeeAdjustmentSupported in
                (action, (networkFeeAdjustmentSupported && action == .send && !amountIsZero) ? .visible : .hidden)
            }
            .map { action, networkFeeVisibility -> SendAuxiliaryViewPresenter.State in
                SendAuxiliaryViewPresenter.State(
                    maxButtonVisibility: networkFeeVisibility.inverted,
                    networkFeeVisibility: networkFeeVisibility,
                    bitpayVisibility: .hidden,
                    availableBalanceTitle: TransactionFlowDescriptor.availableBalanceTitle,
                    maxButtonTitle: TransactionFlowDescriptor.maxButtonTitle(action: action)
                )
            }
            .bindAndCatch(to: sendAuxiliaryViewPresenter.stateRelay)
            .disposeOnDeactivate(interactor: self)
    }

    // swiftlint:enable function_body_length
    // swiftlint:enable cyclomatic_complexity

    // MARK: - Private methods

    private func handleTopAuxiliaryViewTapped(state: TransactionState) {
        switch state.action {
        case .buy:
            transactionModel.process(action: .showTargetSelection)
        case .withdraw:
            presenter.presentWithdrawalLocks(amountAvailable: state.maxSpendable.displayString)
        default:
            break
        }
    }

    private func handleBottomAuxiliaryViewTapped(state: TransactionState) {
        switch state.action {
        case .buy,
             .deposit:
            transactionModel.process(action: .showSourceSelection)
        case .sell,
             .withdraw:
            transactionModel.process(action: .showTargetSelection)
        default:
            unimplemented()
        }
    }

    private func calculateNextState(
        with state: State,
        updater: TransactionState
    ) -> State {
        state
            .update(\.errorState, value: updater.errorState)
            .update(\.canContinue, value: updater.nextEnabled)
            .update(\.showContinueAction, value: canShowContinueAction(for: updater))
            .update(\.showErrorRecoveryAction, value: canShowErrorAction(for: updater))
            .update(\.topAuxiliaryViewPresenter, value: topAuxiliaryView(for: updater))
            .update(\.bottomAuxiliaryViewPresenter, value: bottomAuxiliaryView(for: updater))
            .update(\.showWithdrawalLocks, value: updater.destination is NonCustodialAccount)
    }

    private func canShowContinueAction(for state: TransactionState) -> Bool {
        state.errorState == .none && state.pendingTransaction?.amount.isZero == false
    }

    private func canShowErrorAction(for state: TransactionState) -> Bool {
        state.errorState != .none && state.pendingTransaction?.amount.isZero == false
    }

    private func topAuxiliaryView(for transactionState: TransactionState) -> AuxiliaryViewPresenting? {
        let presenter: AuxiliaryViewPresenting?
        if transactionState.action.supportsTopAccountsView {
            presenter = TargetAuxiliaryViewPresenter(
                delegate: self,
                transactionState: transactionState,
                eventsRecorder: eventsRecorder
            )
        } else {
            presenter = InfoAuxiliaryViewPresenter(
                transactionState: transactionState,
                delegate: self
            )
        }
        topAuxiliaryViewPresenter = presenter
        return presenter
    }

    private func bottomAuxiliaryView(for transactionState: TransactionState) -> AuxiliaryViewPresenting? {
        action.supportsBottomAccountsView ? accountAuxiliaryViewPresenter : sendAuxiliaryViewPresenter
    }

    private func handle(effects: NavigationEffects) {
        switch effects {
        case .back:
            listener?.enterAmountDidTapBack()
        case .close:
            listener?.closeFlow()
        case .none:
            break
        }
    }

    private func handleAmountTranslation(effect: AmountInteractorEffect) {
        switch effect {
        case .failure(let error):
            listener?.showGenericFailure(error: error)
        case .none:
            break
        }
    }

    private func disableAmountViewBadgeIfNeeded() {
        featureFlagService
            .isEnabled(.remote(.newLimitsUIEnabled))
            .asSingle()
            .subscribe(onSuccess: { [amountViewInteractor] isNewLimitsUIEnabled in
                amountViewInteractor.set(auxiliaryViewEnabled: !isNewLimitsUIEnabled)
            })
            .disposeOnDeactivate(interactor: self)
    }
}

extension EnterAmountPageInteractor {

    struct State: Equatable {
        var topAuxiliaryViewPresenter: AuxiliaryViewPresenting?
        var bottomAuxiliaryViewPresenter: AuxiliaryViewPresenting?
        var navigationModel: ScreenNavigationModel
        var canContinue: Bool
        var showContinueAction: Bool
        var showErrorRecoveryAction: Bool
        var showWithdrawalLocks: Bool
        var errorState: TransactionErrorState

        static func == (lhs: EnterAmountPageInteractor.State, rhs: EnterAmountPageInteractor.State) -> Bool {
            lhs.topAuxiliaryViewPresenter === rhs.topAuxiliaryViewPresenter
                && lhs.bottomAuxiliaryViewPresenter === rhs.bottomAuxiliaryViewPresenter
                && lhs.navigationModel == rhs.navigationModel
                && lhs.canContinue == rhs.canContinue
                && lhs.errorState == rhs.errorState
                && lhs.showContinueAction == rhs.showContinueAction
                && lhs.showErrorRecoveryAction == rhs.showErrorRecoveryAction
                && lhs.showWithdrawalLocks == rhs.showWithdrawalLocks
        }
    }

    private func initialState() -> State {
        State(
            topAuxiliaryViewPresenter: nil,
            bottomAuxiliaryViewPresenter: nil,
            navigationModel: navigationModel,
            canContinue: false,
            showContinueAction: false,
            showErrorRecoveryAction: false,
            showWithdrawalLocks: false,
            errorState: .none
        )
    }
}

extension EnterAmountPageInteractor: AuxiliaryViewPresentingDelegate {

    func auxiliaryViewTapped(_ presenter: AuxiliaryViewPresenting, state: TransactionState) {
        if presenter === topAuxiliaryViewPresenter {
            handleTopAuxiliaryViewTapped(state: state)
        } else {
            handleBottomAuxiliaryViewTapped(state: state)
        }
    }
}

extension EnterAmountPageInteractor {

    enum NavigationEffects {
        case back
        case close
        case none
    }
}

extension EnterAmountPageInteractor.State {

    func update<Value>(_ keyPath: WritableKeyPath<Self, Value>, value: Value) -> Self {
        var updated = self
        updated[keyPath: keyPath] = value
        return updated
    }
}

extension TransactionErrorState {

    private typealias LocalizedString = LocalizationConstants.Transaction

    func toAmountInteractorState(
        min: MoneyValue,
        max: MoneyValue,
        exchangeRate: MoneyValuePair?,
        activeInput: ActiveAmountInput,
        stateAmount: MoneyValue,
        listener: EnterAmountPageListener?
    ) -> AmountInteractorState {
        switch self {
        case .none:
            return .inBounds

        case .belowFees:
            return .error(
                message: LocalizedString.Confirmation.Error.insufficientGas
            )

        case .overMaximumSourceLimit,
             .overMaximumPersonalLimit,
             .insufficientFunds:
            let result = convertToInputCurrency(max, exchangeRate: exchangeRate, input: activeInput)
            return .maxLimitExceeded(result)

        case .belowMinimumLimit:
            guard !stateAmount.isZero else {
                return .inBounds
            }
            let result = convertToInputCurrency(min, exchangeRate: exchangeRate, input: activeInput)
            return .underMinLimit(result)

        case .addressIsContract,
             .invalidAddress,
             .invalidPassword,
             .optionInvalid,
             .transactionInFlight,
             .pendingOrdersLimitReached,
             .unknownError,
             .nabuError,
             .fatalError:
            return .empty
        }
    }

    private func convertToInputCurrency(
        _ source: MoneyValue,
        exchangeRate: MoneyValuePair?,
        input: ActiveAmountInput
    ) -> MoneyValue {
        switch (source.currency, input) {
        case (.crypto, .crypto),
             (.fiat, .fiat):
            return source
        case (.crypto, .fiat):
            // Convert crypto max amount into fiat amount.
            guard let exchangeRate = exchangeRate else {
                // No exchange rate yet, use original value for error message.
                return source
            }
            // Convert crypto max amount into fiat amount.
            return source.convert(using: exchangeRate.quote)
        case (.fiat, .crypto):
            guard let exchangeRate = exchangeRate else {
                // No exchange rate yet, use original value for error message.
                return source
            }
            // Convert fiat max amount into crypto amount.
            return source.convert(usingInverse: exchangeRate.quote, currencyType: source.currency)
        }
    }
}

extension AssetAction {

    fileprivate var supportsTopAccountsView: Bool {
        switch self {
        case .buy:
            return true
        default:
            return false
        }
    }

    fileprivate var supportsBottomAccountsView: Bool {
        switch self {
        case .buy,
             .deposit,
             .withdraw:
            return true
        default:
            return false
        }
    }
}
