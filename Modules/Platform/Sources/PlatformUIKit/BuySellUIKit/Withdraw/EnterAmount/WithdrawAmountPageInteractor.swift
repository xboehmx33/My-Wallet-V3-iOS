// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import Localization
import MoneyKit
import PlatformKit
import RIBs
import RxCocoa
import RxSwift
import ToolKit

protocol WithdrawAmountPageRouting: AnyObject {
    func showError()
}

protocol WithdrawAmountPageListener: AnyObject {
    func showCheckoutScreen(checkoutData: WithdrawalCheckoutData)
    func enterAmountDidTapBack()
    func closeFlow()
}

protocol WithdrawAmountPagePresentable: Presentable {
    var continueButtonTapped: Signal<Void> { get }

    func connect(state: Driver<WithdrawAmountPageInteractor.State>) -> Driver<WithdrawAmountPageInteractor.Effects>
}

final class WithdrawAmountPageInteractor: PresentableInteractor<WithdrawAmountPagePresentable>,
    WithdrawAmountPageInteractable
{

    private typealias AnalyticsEvent = AnalyticsEvents.FiatWithdrawal
    private typealias LocalizatedStrings = LocalizationConstants.FiatWithdrawal.EnterAmountScreen

    weak var router: WithdrawAmountPageRouting?
    weak var listener: WithdrawAmountPageListener?

    private let withdrawalFeeService: WithdrawalFeeService
    private let validationService: WithdrawAmountValidationService

    /// The interactor that `SendAuxiliaryViewPresenter` uses
    private let auxiliaryViewInteractor: SendAuxiliaryViewInteractorAPI
    /// The interactor that `SingleAmountPreseneter` uses
    private let amountInteractor: SingleAmountInteractor

    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let loadingViewPresenter: LoadingViewPresenting
    private let alertViewPresenter: AlertViewPresenterAPI

    private let fiatCurrency: FiatCurrency
    private let beneficiary: Beneficiary

    init(
        presenter: WithdrawAmountPagePresentable,
        fiatCurrency: FiatCurrency,
        beneficiary: Beneficiary,
        amountInteractor: SingleAmountInteractor,
        withdrawalFeeService: WithdrawalFeeService,
        validationService: WithdrawAmountValidationService,
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve(),
        loadingViewPresenter: LoadingViewPresenting = resolve(),
        alertViewPresenter: AlertViewPresenterAPI = resolve()
    ) {
        self.fiatCurrency = fiatCurrency
        self.beneficiary = beneficiary
        self.amountInteractor = amountInteractor
        auxiliaryViewInteractor = SendAuxiliaryViewInteractor(currencyType: fiatCurrency.currencyType)
        self.withdrawalFeeService = withdrawalFeeService
        self.analyticsRecorder = analyticsRecorder
        self.validationService = validationService
        self.alertViewPresenter = alertViewPresenter
        self.loadingViewPresenter = loadingViewPresenter
        super.init(presenter: presenter)
    }

    override func didBecomeActive() {
        super.didBecomeActive()

        let amountInput = amountInteractor.amount
            .map(WithdrawAmountValidationService.Input.amount)

        let resetToMaxInput = auxiliaryViewInteractor.resetToMaxAmount
            .flatMap(weak: self) { (self, _) -> Observable<WithdrawAmountValidationService.Input> in
                self.validationService.balance
                    .do(onSuccess: { moneyValue in
                        self.amountInteractor.set(amount: moneyValue)
                    })
                    .map { _ in .withdrawMax }
                    .asObservable()
                    .take(1)
            }

        let validationState = validationService
            .connect(inputs: .merge(amountInput, resetToMaxInput))
            .share(replay: 1, scope: .whileConnected)

        // we need to bind the validated state back to `AmountInteractor` stateRelay
        validationState
            .map(\.toAmountInteractorState)
            .bindAndCatch(to: amountInteractor.stateRelay)
            .disposeOnDeactivate(interactor: self)

        let viewModel = TransactionDescriptorViewModel(assetAction: .withdraw, adjustActionIconColor: true)
        validationService.account
            .map(TransactionDescriptorViewModel.TransactionAccountValue.value)
            .bindAndCatch(to: viewModel.fromAccountRelay)
            .disposeOnDeactivate(interactor: self)

        let interactorState = validationState
            .scan(initialState(descriptorViewModel: viewModel)) { state, updater -> State in
                var state = state
                return state.update(\.canContinue, value: updater.isValid)
            }
            .asDriverCatchError()

        presenter.continueButtonTapped
            .asObservable()
            .show(loader: loadingViewPresenter, style: .circle)
            .withLatestFrom(validationState.map(\.data))
            .flatMap(weak: self) { (self, data) -> Observable<WithdrawalCheckoutData> in
                guard let data = data else { return .empty() }
                return self.withdrawalFeeService.withdrawCheckoutData(data: data)
                    .asObservable()
                    .catchError { _ -> Observable<WithdrawalCheckoutData> in
                        self.loadingViewPresenter.hide()
                        self.router?.showError()
                        return .empty()
                    }
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] checkoutData in
                self?.loadingViewPresenter.hide()
                let event = AnalyticsEvent.confirm(
                    currencyCode: checkoutData.currency.code,
                    amount: checkoutData.amount.displayString
                )
                self?.analyticsRecorder.record(event: event)
                self?.listener?.showCheckoutScreen(checkoutData: checkoutData)
            })
            .disposeOnDeactivate(interactor: self)

        presenter.connect(state: interactorState)
            .drive(onNext: handle(effects:))
            .disposeOnDeactivate(interactor: self)
    }

    // MARK: - Private methods

    private func handle(effects: Effects) {
        switch effects {
        case .back:
            listener?.enterAmountDidTapBack()
        case .close:
            listener?.closeFlow()
        case .none:
            break
        }
    }

    private func initialState(descriptorViewModel: TransactionDescriptorViewModel) -> State {
        let topSelectionTitle = String(
            format: LocalizatedStrings.from,
            fiatCurrency.displayCode
        )
        let bottomSelectionTitle = String(
            format: LocalizatedStrings.to,
            beneficiary.name,
            beneficiary.account
        )
        let topSelectionState = TopSelectionState(
            title: topSelectionTitle,
            subtitle: bottomSelectionTitle,
            isEnabled: false,
            trailingContent: .transaction(descriptorViewModel),
            leadingContent: .none
        )
        let auxiliaryPresenterState = SendAuxiliaryViewPresenter.State(
            maxButtonVisibility: .visible,
            networkFeeVisibility: .hidden,
            bitpayVisibility: .hidden,
            availableBalanceTitle: LocalizatedStrings.available,
            maxButtonTitle: LocalizatedStrings.withdrawMax
        )
        let bottomAuxiliaryState = BottomAuxiliaryViewModelState.maxAvailable(
            SendAuxiliaryViewPresenter(
                interactor: auxiliaryViewInteractor,
                initialState: auxiliaryPresenterState
            )
        )

        return State(
            topSelection: topSelectionState,
            bottomAuxiliaryState: bottomAuxiliaryState,
            canContinue: false
        )
    }
}

extension WithdrawAmountPageInteractor {
    struct State {
        var topSelection: TopSelectionState
        var bottomAuxiliaryState: BottomAuxiliaryViewModelState
        var canContinue: Bool
    }

    /// The state of the top selection view
    struct TopSelectionState {
        var title: String
        var subtitle: String
        var isEnabled: Bool
        var horizontalOffset: CGFloat = 0
        var trailingContent: SelectionButtonViewModel.TrailingContent?
        var leadingContent: SelectionButtonViewModel.LeadingContentType?
        var accessibilityContent: SelectionButtonViewModel.AccessibilityContent?
    }

    /// The state of the bottom auxiliary view
    enum BottomAuxiliaryViewModelState {
        /// Max available style button with available amount for spending and use-maximum button
        case maxAvailable(SendAuxiliaryViewPresenter)

        /// Hidden - nothing to present
        case hidden
    }
}

extension WithdrawAmountPageInteractor {
    enum Effects {
        case back
        case close
        case none
    }
}

extension WithdrawAmountPageInteractor.State {
    mutating func update<Value>(_ keyPath: WritableKeyPath<Self, Value>, value: Value) -> Self {
        var updated = self
        updated[keyPath: keyPath] = value
        return updated
    }
}

extension WithdrawAmountPageInteractor.BottomAuxiliaryViewModelState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.hidden, .hidden):
            return true
        case (.maxAvailable, .maxAvailable):
            return true
        default:
            return false
        }
    }
}
