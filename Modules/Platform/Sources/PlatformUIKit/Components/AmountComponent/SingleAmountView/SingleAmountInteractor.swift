// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import MoneyKit
import PlatformKit
import RxCocoa
import RxSwift
import ToolKit

public final class SingleAmountInteractor: AmountViewInteracting {

    // MARK: - Properties

    public let effect: Observable<AmountInteractorEffect> = .just(.none)
    public let activeInput: Observable<ActiveAmountInput>

    /// The state of the component
    public let stateRelay = BehaviorRelay<AmountInteractorState>(value: .empty)
    public var state: Observable<AmountInteractorState> {
        stateRelay.asObservable()
            .share(replay: 1, scope: .whileConnected)
    }

    public let auxiliaryButtonTappedRelay = PublishRelay<Void>()
    public let auxiliaryViewEnabledRelay = PublishRelay<Bool>()

    /// Streams the amount of `MoneyValue`
    public let amount: Observable<MoneyValue>

    public let currencyInteractor: InputAmountLabelInteractor
    public let inputCurrency: Currency

    // This interactor doesn't support min/max
    public var minAmountSelected: Observable<Void> = .never()
    public var maxAmountSelected: Observable<Void> = .never()

    // MARK: - Private

    private let currencyService: CurrencyServiceAPI

    private let disposeBag = DisposeBag()

    public init(
        currencyService: CurrencyServiceAPI,
        inputCurrency: Currency
    ) {
        activeInput = .just(inputCurrency.isFiatCurrency ? .fiat : .crypto)
        self.currencyService = currencyService
        self.inputCurrency = inputCurrency
        currencyInteractor = InputAmountLabelInteractor(currency: inputCurrency)

        amount = currencyInteractor
            .scanner
            .input
            .compactMap { [inputCurrency] input -> MoneyValue? in
                let amount = input.isEmpty || input.isPlaceholderZero ? "0" : input.amount
                return MoneyValue.create(major: amount, currency: inputCurrency.currencyType)
            }
            .share(replay: 1, scope: .whileConnected)
    }

    public func connect(input: Driver<AmountInteractorInput>) -> Driver<AmountInteractorState> {
        // Input Actions
        input.map(\.toInputScannerAction)
            .asObservable()
            .bindAndCatch(to: currencyInteractor.scanner.actionRelay)
            .disposed(by: disposeBag)

        state
            .map(\.toValidationState)
            .bindAndCatch(to: currencyInteractor.interactor.stateRelay)
            .disposed(by: disposeBag)

        return state
            .asDriver(onErrorJustReturn: .empty)
    }

    public func set(amount: String) {
        currencyInteractor.scanner
            .rawInputRelay
            .accept(amount)
    }

    public func set(amount: MoneyValue) {
        currencyInteractor
            .scanner
            .reset(to: amount)
    }

    public func set(auxiliaryViewEnabled: Bool) {
        auxiliaryViewEnabledRelay.accept(auxiliaryViewEnabled)
    }
}

extension AmountInteractorInput {
    internal var toInputScannerAction: MoneyValueInputScanner.Action {
        switch self {
        case .insert(let value):
            return .insert(value)
        case .remove:
            return .remove
        }
    }
}
