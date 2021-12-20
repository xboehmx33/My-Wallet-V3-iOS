// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit
import UIKit

// swiftlint:disable file_length

public protocol TierUpgradeRouterAPI {

    /// Presents a `UIViewController` prompting the user to upgrade to a higher tier. Usually Tier 2 (Gold).
    /// - Parameters:
    ///   - presenter: The `UIViewController` from where the prompt has to be presenter. If you pass `nil` the app's top most view controller will be used.
    ///   - completion: A closure called ONLY if the user successfully upgrades to a new Tier.
    func presentPromptToUpgradeTier(from presenter: UIViewController?, completion: @escaping () -> Void)
}

public final class StateService: StateServiceAPI {

    // MARK: - Types

    /// Comprise all the states so far in the current Simple-Buy session
    struct States {

        /// The actual state of the flow
        let current: State

        /// The previous states sorted chronologically
        let previous: [State]

        /// A computed inactive state
        static var inactive: States {
            States(current: .inactive, previous: [])
        }

        /// Maps the instance of `States` into a new instance where the appended
        /// state is the current
        func states(byAppending state: State) -> States {
            States(
                current: state,
                previous: previous + [current]
            )
        }

        /// Maps the instance of `States` into a new instance where the last
        /// state is trimmed off. In case `previous` is an empty array, `current` will be
        /// `.inactive`.
        func statesByRemovingLast() -> States {
            States(
                current: previous.last ?? .inactive,
                previous: previous.dropLast()
            )
        }
    }

    /// Marks a past or present state in the state-machine
    public enum State {

        /// First time the user performs the simple buy flow
        case intro

        /// Fiat Selection
        case selectFiat

        /// Fiat selection is not supported in SB
        case unsupportedFiat(FiatCurrency)

        /// In the middle of the buy screen
        case buy

        /// Change your fiat type from the `Buy` screen.
        /// Shows only supported `fiat` types
        case changeFiat

        /// The user wants to view his payment method types
        case paymentMethods

        /// The user would enter add-card flow before checking out
        case addCard(CheckoutData)

        /// During KYC process
        case kycBeforeCheckout(CheckoutData)

        /// KYC
        case kyc

        /// Show a given URL
        case showURL(URL)

        /// Pending KYC approval
        case pendingKycApproval(CheckoutData)

        /// Ineligible
        case ineligible

        /// The user is checking-out
        case checkout(CheckoutData)

        /// The user authorized his bank wire
        case bankTransferDetails(CheckoutData)

        /// Funds transfer details
        case fundsTransferDetails(currency: CurrencyType, isOriginPaymentMethods: Bool, isOriginDeposit: Bool)

        /// The user authorized his card payment and should now be referred to partner
        case authorizeCard(order: OrderDetails)

        /// The user authorized open banking payment and should now be referred to partner
        case authorizeOpenBanking(CheckoutData)

        /// The user may cancel their transfer
        case transferCancellation(CheckoutData)

        /// The user has a pending order
        case pendingOrderDetails(CheckoutData)

        /// Purchase completed
        case pendingOrderCompleted(orderDetails: OrderDetails)

        /// The user will be taken to link a card flow
        case linkCard

        /// The user will be taken to link a bank flow
        case linkBank

        /// Inactive state - no buy flow is performed at the moment
        case inactive

        var isPaymentMethods: Bool {
            switch self {
            case .paymentMethods:
                return true
            default:
                return false
            }
        }
    }

    public enum Action {
        case next(to: State)
        case previous(from: State)
        case dismiss
    }

    // MARK: - Properties

    var states: Observable<States> {
        statesRelay.asObservable()
    }

    var currentState: Observable<StateService.State> {
        states.map(\.current)
    }

    public var action: Observable<Action> {
        actionRelay
            .observeOn(MainScheduler.instance)
    }

    public let nextRelay = PublishRelay<Void>()
    public let previousRelay = PublishRelay<Void>()

    public let cache: Atomic<EventCache>

    private let supportedPairsInteractor: SupportedPairsInteractorServiceAPI
    private let paymentAccountService: PaymentAccountServiceAPI
    private let pendingOrderDetailsService: PendingOrderDetailsServiceAPI
    private let kycTiersService: KYCTiersServiceAPI
    private let statesRelay = BehaviorRelay<States>(value: .inactive)
    private let actionRelay = PublishRelay<Action>()
    private let loader: LoadingViewPresenting
    private let alert: AlertViewPresenterAPI
    private let messageRecorder: MessageRecording
    private let tierUpgradeRouter: TierUpgradeRouterAPI

    private let disposeBag = DisposeBag()

    // MARK: - Setup

    public init(
        supportedPairsInteractor: SupportedPairsInteractorServiceAPI = resolve(),
        paymentAccountService: PaymentAccountServiceAPI = resolve(),
        pendingOrderDetailsService: PendingOrderDetailsServiceAPI = resolve(),
        kycTiersService: KYCTiersServiceAPI = resolve(),
        cache: EventCache = resolve(),
        loader: LoadingViewPresenting = resolve(),
        alert: AlertViewPresenterAPI = resolve(),
        tierUpgradeRouter: TierUpgradeRouterAPI = resolve(),
        messageRecorder: MessageRecording = resolve()
    ) {
        self.supportedPairsInteractor = supportedPairsInteractor
        self.paymentAccountService = paymentAccountService
        self.pendingOrderDetailsService = pendingOrderDetailsService
        self.kycTiersService = kycTiersService
        self.cache = Atomic(cache)
        self.loader = loader
        self.alert = alert
        self.messageRecorder = messageRecorder
        self.tierUpgradeRouter = tierUpgradeRouter

        nextRelay
            .observeOn(MainScheduler.instance)
            .bindAndCatch(weak: self) { (self) in self.next() }
            .disposed(by: disposeBag)

        previousRelay
            .observeOn(MainScheduler.instance)
            .bindAndCatch(weak: self) { (self) in self.previous() }
            .disposed(by: disposeBag)
    }

    public func cardRoutingInteractor(with checkoutData: CheckoutData?) -> CardRouterInteractor {
        let interactor = CardRouterInteractor()
        interactor.completionCardData
            .observeOn(MainScheduler.asyncInstance)
            .bindAndCatch(weak: self) { (self, cardData) in
                self.previous()
                if let checkoutData = checkoutData?.checkoutData(byAppending: cardData) {
                    self.nextFromBuyCrypto(with: checkoutData)
                }
            }
            .disposed(by: disposeBag)

        interactor.cancellation
            .observeOn(MainScheduler.asyncInstance)
            .bindAndCatch(weak: self) { (self) in
                self.previous()
            }
            .disposed(by: disposeBag)

        return interactor
    }

    private func next() {
        let states = statesRelay.value
        messageRecorder.record("StateService: next: \(states.debugDescription)")
        let state: State
        switch states.current {
        case .inactive:
            startFlow()
        case .intro:
            state = .selectFiat
            apply(
                action: .next(to: state),
                states: self.states(byAppending: state)
            )
        case .kycBeforeCheckout(let data):
            checkSDDVerificationAndContinue(with: data)
        case .pendingKycApproval(let data):
            applyStateToContinueCheckoutAfterKYC(using: data)
        case .bankTransferDetails,
             .fundsTransferDetails,
             .pendingOrderDetails,
             .transferCancellation,
             .unsupportedFiat,
             .showURL,
             .changeFiat,
             .linkCard,
             .linkBank:
            state = .inactive
            apply(
                action: .dismiss,
                states: self.states(byAppending: state)
            )
        case .kyc:
            statesRelay.accept(statesByRemovingLast())
        case .buy,
             .checkout,
             .paymentMethods,
             .selectFiat,
             .addCard,
             .authorizeCard,
             .authorizeOpenBanking,
             .pendingOrderCompleted,
             .ineligible:
            fatalError("\(#function) was called with unhandled state: \(states.debugDescription).")
        }
    }

    private func previous() {
        let last = statesRelay.value.current
        if case .pendingOrderCompleted = last {
            // Cannot go back once the order is completed.
            // This fixes an issue with performing KYC after a successful order.
            return
        }

        let states = statesByRemovingLast()
        let current = states.current
        let action: Action
        switch (last, current) {
        /// Dismiss in case the current state is `inactive`.
        /// Dismiss in case the last state is `pendingKycApproval` (end user tapped the continue button)
        case (_, .inactive),
             (.pendingKycApproval, _),
             (.ineligible, _):
            action = .dismiss
        default:
            action = .previous(from: last)
        }
        apply(action: action, states: states)
    }

    private func startFlow() {
        let cache = cache
        let isFiatCurrencySupported: Single<Bool> = supportedPairsInteractor.pairs
            .take(1)
            .asSingle()
            .map { !$0.pairs.isEmpty }

        let isTier2Approved = kycTiersService
            .fetchTiers()
            .asSingle()
            .map(\.isTier2Approved)

        Single
            .zip(
                pendingOrderDetailsService.pendingOrderDetails.map(\.first),
                isFiatCurrencySupported
            ) { (pendingOrderDetails: $0, isFiatCurrencySupported: $1) }
            .observeOn(MainScheduler.asyncInstance)
            .handleLoaderForLifecycle(
                loader: loader,
                style: .circle
            )
            .flatMap { data -> Single<State> in
                if let orderDetails = data.pendingOrderDetails {
                    let checkoutData = CheckoutData(order: orderDetails)
                    switch orderDetails.state {
                    /// If the order is in `pendingConfirmation` check if the user is tier two approved.
                    /// In case the user is KYCed: send the user to checkout to complete the order
                    /// In case the user has not KYCed yet: Go to the main buy screen to re-enter amount,
                    /// recreate the order, and then to KYC.
                    case .pendingConfirmation:
                        return isTier2Approved
                            .map { isTier2Approved in
                                // User must be GOLD to get to checkout
                                guard isTier2Approved else {
                                    return .buy
                                }
                                // If the order is card but payment method id is missing - navigate to the main amount screen
                                if checkoutData.isUnknownCardType || checkoutData.isUnknownBankTransfer {
                                    return .buy
                                }
                                // If this is not a Buy order - navigate to the main amount screen
                                guard checkoutData.order.isBuy else {
                                    return .buy
                                }
                                return .checkout(checkoutData)
                            }
                    default:
                        switch orderDetails.paymentMethod {
                        case .card:
                            if orderDetails.is3DSConfirmedCardOrder {
                                return .just(
                                    .pendingOrderCompleted(
                                        orderDetails: orderDetails
                                    )
                                )
                            } else {
                                return .just(.checkout(checkoutData))
                            }
                        case .bankTransfer:
                            return .just(.checkout(checkoutData))
                        case .bankAccount:
                            return .just(.pendingOrderDetails(checkoutData))
                        case .funds:
                            return .just(.pendingOrderDetails(checkoutData))
                        }
                    }
                } else {
                    if cache.value[.hasShownIntroScreen] {
                        return .just(data.isFiatCurrencySupported ? .buy : .selectFiat)
                    } else {
                        return .just(.intro)
                    }
                }
            }
            .subscribe(
                onSuccess: { [weak self] state in
                    guard let self = self else { return }
                    /// The user already has a pending order, so
                    /// mark the intro screen as `shown`.
                    switch state {
                    case .checkout, .pendingOrderDetails, .pendingOrderCompleted, .bankTransferDetails:
                        cache.mutate { $0[.hasShownIntroScreen] = true }
                    default:
                        break
                    }

                    self.apply(
                        action: .next(to: state),
                        states: self.states(byAppending: state)
                    )
                },
                onError: { [weak alert] _ in
                    alert?.error(in: nil, action: nil)
                }
            )
            .disposed(by: disposeBag)
    }

    private func apply(action: Action, states: States) {
        messageRecorder.record("StateService: apply: \(action) and \(states.debugDescription)")
        actionRelay.accept(action)
        statesRelay.accept(states)
        cache(state: states.current)
    }

    private func cache(state: State) {
        switch state {
        case .buy:
            cache.mutate { $0[.hasShownBuyScreen] = true }
        case .intro:
            cache.mutate { $0[.hasShownIntroScreen] = true }
        default:
            break
        }
    }

    private func statesByRemovingLast() -> States {
        messageRecorder.record("StateService: removing last: \(statesRelay.value.debugDescription)")
        return statesRelay.value.statesByRemovingLast()
    }

    private func states(byAppending state: State) -> States {
        messageRecorder.record("StateService: appending state: \(state.debugDescription) to \(statesRelay.value.debugDescription)")
        return statesRelay.value.states(byAppending: state)
    }

    private func checkTier3Verification() -> Single<Bool> {
        kycTiersService.checkSimplifiedDueDiligenceVerification(pollUntilComplete: false)
            .asSingle()
    }

    private func checkSDDVerificationAndContinue(with data: CheckoutData) {
        checkTier3Verification()
            .subscribe { [weak self] isTier3Verified in
                if isTier3Verified {
                    self?.applyStateToContinueCheckoutAfterKYC(using: data)
                } else {
                    self?.applyStateToPendingKYC(using: data)
                }
            } onError: { [weak self] error in
                Logger.shared.error(error)
                self?.applyStateToPendingKYC(using: data)
            }
            .disposed(by: disposeBag)
    }

    private func applyStateToPendingKYC(using data: CheckoutData) {
        let state: State = .pendingKycApproval(data)
        apply(
            action: .next(to: state),
            states: states(byAppending: state)
        )
    }

    private func applyStateToContinueCheckoutAfterKYC(using data: CheckoutData) {
        // After KYC - add card if necessary or link a bank flow for bank transfer
        let state: State
        switch data.order.paymentMethod {
        case .funds:
            state = .fundsTransferDetails(
                currency: data.order.inputValue.currency,
                isOriginPaymentMethods: false,
                isOriginDeposit: false
            )
        case .card where !data.isPaymentMethodFinalized:
            state = .addCard(data)
        case .bankTransfer where !data.isPaymentMethodFinalized:
            state = .linkBank
        default:
            state = .checkout(data)
        }
        apply(
            action: .next(to: state),
            states: states(byAppending: state)
        )
    }
}

// MARK: - PaymentMethods

extension StateService {

    public func showFundsTransferDetails(for fiatCurrency: FiatCurrency, isOriginDeposit: Bool) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let currentState = self.statesRelay.value.current
            if currentState.isPaymentMethods {
                self.statesRelay.accept(self.statesByRemovingLast())
            }
            let states = self.states(
                byAppending: .fundsTransferDetails(
                    currency: .fiat(fiatCurrency),
                    isOriginPaymentMethods: currentState.isPaymentMethods,
                    isOriginDeposit: isOriginDeposit
                )
            )
            self.apply(action: .next(to: states.current), states: states)
        }
    }
}

// MARK: - ElibilityRelayAPI

extension StateService {

    public func ineligible(with currency: FiatCurrency) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .unsupportedFiat(currency))
            self.apply(action: .next(to: states.current), states: states)
        }
    }
}

// MARK: - URLSelectionServiceAPI

extension StateService {

    public func show(url: URL) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .showURL(url))
            self.apply(action: .next(to: states.current), states: states)
        }
    }
}

// MARK: - CheckoutServiceAPI

extension StateService {

    public func nextFromBuyCrypto(with checkoutData: CheckoutData) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let state: State
            switch checkoutData.order.paymentMethod {
            case .card where !checkoutData.isPaymentMethodFinalized:
                state = .addCard(checkoutData)
            case .bankTransfer where !checkoutData.isPaymentMethodFinalized:
                state = .linkBank
            default:
                state = .checkout(checkoutData)
            }

            let states = self.states(byAppending: state)
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func nextFromCardLinkSelection() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .linkCard)
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func nextFromBankLinkSelection() {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .linkBank)
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func kyc(with checkoutData: CheckoutData) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .kycBeforeCheckout(checkoutData))
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func kyc() {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let currentState = self.statesRelay.value.current
            if currentState.isPaymentMethods {
                self.statesRelay.accept(self.statesByRemovingLast())
            }
            let states = self.states(byAppending: .kyc)
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func ineligible(with checkoutData: CheckoutData) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .pendingKycApproval(checkoutData))
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func ineligible() {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .ineligible)
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func paymentMethods() {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .paymentMethods)
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func changeCurrency() {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .changeFiat)
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func bankTransferDetails(with checkoutData: CheckoutData) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .bankTransferDetails(checkoutData))
            self.apply(action: .next(to: states.current), states: states)
        }
    }
}

// MARK: - CurrencySelectionServiceAPI

extension StateService {

    public func currencySelected() {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .buy)
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func reselectCurrency() {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.previousRelay.accept(())
            let states = self.states(byAppending: .selectFiat)
            self.apply(action: .next(to: states.current), states: states)
        }
    }
}

// MARK: - ConfirmCheckoutServiceAPI

extension StateService {

    public func confirmCheckout(with checkoutData: CheckoutData, isOrderNew: Bool) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let state: State
            let data = (checkoutData.order.paymentMethod, isOrderNew)
            switch data {
            case (.funds, true):
                state = .pendingOrderCompleted(
                    orderDetails: checkoutData.order
                )
            case (.bankAccount, true):
                state = .bankTransferDetails(checkoutData)
            case (.bankTransfer, _) where checkoutData.linkedBankData?.partner == .yapily:
                state = .authorizeOpenBanking(
                    checkoutData
                )
            case (.bankTransfer, true):
                state = .pendingOrderCompleted(
                    orderDetails: checkoutData.order
                )
            case (.bankAccount, false),
                 (.bankTransfer, false),
                 (.funds, false):
                state = .inactive
            case (.card, _):
                state = .authorizeCard(order: checkoutData.order)
            }

            let states = self.states(byAppending: state)
            self.apply(action: .next(to: state), states: states)
        }
    }
}

extension StateService {

    public func cancelTransfer(with checkoutData: CheckoutData) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .transferCancellation(checkoutData))
            self.apply(action: .next(to: states.current), states: states)
        }
    }
}

extension StateService {

    public func cardAuthorized(with paymentMethodId: String) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard case .authorizeCard(order: let order) = self.statesRelay.value.current else {
                return
            }
            let states = self.states(
                byAppending: .pendingOrderCompleted(
                    orderDetails: order
                )
            )
            self.apply(action: .next(to: states.current), states: states)
        }
    }
}

extension StateService {

    public func orderCompleted() {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let states = self.states(byAppending: .inactive)
            self.apply(action: .next(to: states.current), states: states)
        }
    }

    public func orderPending(with orderDetails: OrderDetails) {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let checkoutData = CheckoutData(order: orderDetails)
            let state = State.checkout(checkoutData)
            self.apply(
                action: .next(to: state),
                states: self.states(byAppending: state)
            )
        }
    }

    public func promptTierUpgrade() {
        tierUpgradeRouter.presentPromptToUpgradeTier(from: nil) { [weak self] in
            self?.orderCompleted()
        }
    }
}

extension StateService {

    public func authorizedOpenBanking() {
        ensureIsOnMainQueue()
        DispatchQueue.main.async { [self] in
            guard case .authorizeOpenBanking(let data) = statesRelay.value.current else {
                return assertionFailure("Got authorizedOpenBanking when state was not equal to authorizeOpenBanking")
            }

            let states = states(
                byAppending: .pendingOrderCompleted(
                    orderDetails: data.order
                )
            )
            apply(action: .next(to: states.current), states: states)
        }
    }
}
