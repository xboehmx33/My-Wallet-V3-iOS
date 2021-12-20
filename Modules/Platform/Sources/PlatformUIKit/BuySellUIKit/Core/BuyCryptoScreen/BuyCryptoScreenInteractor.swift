// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxRelay
import RxSwift
import ToolKit

final class BuyCryptoScreenInteractor: EnterAmountScreenInteractor {

    // MARK: - Types

    enum State {
        case inBounds(data: CandidateOrderDetails, upperLimit: FiatValue)
        case tooLow(min: FiatValue)
        case tooHigh(max: FiatValue)
        case empty(currency: FiatCurrency)

        var isValid: Bool {
            switch self {
            case .inBounds:
                return true
            default:
                return false
            }
        }

        var isEmpty: Bool {
            switch self {
            case .empty:
                return true
            default:
                return false
            }
        }
    }

    enum Effect {
        case failure(Error)
        case none
    }

    // MARK: - Properties

    /// Exposes a stream of the currently selected `CryptoCurrency` value
    override var selectedCurrencyType: Observable<CurrencyType> {
        cryptoCurrencySelectionService.selectedData.map(\.cryptoCurrency.currencyType).asObservable()
    }

    /// The state of the screen with associated data
    var state: Observable<State> {
        stateRelay.asObservable()
    }

    /// Whether the state of the screen is valid
    override var hasValidState: Observable<Bool> {
        state.map(\.isValid)
    }

    /// The (optional) data, in case the state's value is `inBounds`.
    /// `nil` otherwise.
    var candidateOrderDetails: Observable<CandidateOrderDetails?> {
        state
            .map { state in
                switch state {
                case .inBounds(data: let data, upperLimit: _):
                    return data
                default:
                    return nil
                }
            }
    }

    // MARK: - Output (readable)

    /// Calculation state of the supported pairs
    var pairsCalculationState: Observable<BuyCryptoSupportedPairsCalculationState> {
        pairsCalculationStateRelay.asObservable()
    }

    /// Suggested amounts, each represented a `Decimal value`
    var suggestedAmounts: Observable<[FiatValue]> {
        suggestedAmountsRelay.asObservable()
    }

    /// Streams a `KycState` indicating whether the user should complete KYC
    var currentKycState: Single<Result<KycState, Error>> {
        kycTiersService.fetchTiers()
            .asSingle()
            .map(\.isTier2Approved)
            .mapToResult(successMap: { $0 ? .completed : .shouldComplete })
    }

    /// Streams a boolean indicating whether the user is eligible to Simple Buy
    var currentEligibilityState: Observable<Result<Bool, Error>> {
        eligibilityService
            .fetch()
            .mapToResult()
            .asObservable()
    }

    var paymentMethodTypes: Observable<[PaymentMethodType]> {
        Observable
            .combineLatest(
                paymentMethodTypesService.methodTypes,
                fiatCurrencyService.displayCurrencyPublisher.asObservable(),
                kycTiersService.tiers.map(\.isTier2Approved).asObservable(),
                featureFlagsService
                    .isEnabled(.remote(.openBanking))
                    .asObservable()
            )
            .map { methods, fiatCurrency, isTier2Approved, isOpenBankingEnabled in
                methods.filterValidForBuy(
                    currentWalletCurrency: fiatCurrency,
                    accountForEligibility: isTier2Approved,
                    isOpenBankingEnabled: isOpenBankingEnabled
                )
            }
            .catchErrorJustReturn([])
    }

    var preferredPaymentMethodType: Observable<PaymentMethodType?> {
        paymentMethodTypesService.preferredPaymentMethodType
    }

    /// An observable stream with a value of an effect.
    var effect: Observable<Effect> {
        effectRelay
            .asObservable()
    }

    // MARK: - Dependencies

    private let kycTiersService: KYCTiersServiceAPI
    private let suggestedAmountsService: SuggestedAmountsServiceAPI
    private let pairsService: SupportedPairsInteractorServiceAPI
    private let eligibilityService: EligibilityServiceAPI
    private let paymentMethodTypesService: PaymentMethodTypesServiceAPI
    private let orderCreationService: OrderCreationServiceAPI
    private let featureFlagsService: FeatureFlagsServiceAPI

    // MARK: - Accessors

    private let suggestedAmountsRelay = BehaviorRelay<[FiatValue]>(value: [])

    /// The fiat-crypto pairs
    private let pairsCalculationStateRelay = BehaviorRelay<BuyCryptoSupportedPairsCalculationState>(
        value: .invalid(.empty)
    )

    /// The state of the screen
    private let stateRelay = BehaviorRelay<State>(value: .empty(currency: FiatCurrency.default))

    /// A relay that streams an effect, such as a failure
    private let effectRelay = BehaviorRelay<Effect>(value: .none)

    private let disposeBag = DisposeBag()

    // MARK: - Setup

    init(
        kycTiersService: KYCTiersServiceAPI = resolve(),
        priceService: PriceServiceAPI = resolve(),
        paymentMethodTypesService: PaymentMethodTypesServiceAPI,
        fiatCurrencyService: FiatCurrencyServiceAPI = resolve(),
        cryptoCurrencySelectionService: CryptoCurrencySelectionServiceAPI,
        pairsService: SupportedPairsInteractorServiceAPI = resolve(),
        eligibilityService: EligibilityServiceAPI = resolve(),
        orderCreationService: OrderCreationServiceAPI = resolve(),
        suggestedAmountsService: SuggestedAmountsServiceAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        self.kycTiersService = kycTiersService
        self.pairsService = pairsService
        self.suggestedAmountsService = suggestedAmountsService
        self.eligibilityService = eligibilityService
        self.paymentMethodTypesService = paymentMethodTypesService
        self.orderCreationService = orderCreationService
        self.featureFlagsService = featureFlagsService
        super.init(
            priceService: priceService,
            fiatCurrencyService: fiatCurrencyService,
            cryptoCurrencySelectionService: cryptoCurrencySelectionService,
            initialActiveInput: .fiat
        )
    }

    // MARK: - Interactor

    // swiftlint:disable:next cyclomatic_complexity
    // swiftlint:disable function_body_length
    override func didLoad() {

        let cryptoCurrencySelectionService = cryptoCurrencySelectionService
        let fiatCurrencyService = fiatCurrencyService

        amountTranslationInteractor.effect
            .map(\.toBuyCryptoInteractorEffect)
            .bindAndCatch(to: effectRelay)
            .disposed(by: disposeBag)

        state
            .observeOn(MainScheduler.asyncInstance)
            .flatMapLatest(weak: self) { (self, state) -> Observable<AmountInteractorState> in
                Single
                    .zip(
                        self.amountTranslationInteractor.activeInputRelay.take(1).asSingle(),
                        cryptoCurrencySelectionService.cryptoCurrency
                    )
                    .flatMap(weak: self) { (self, values) -> Single<AmountInteractorState> in
                        let (activeInput, currency) = values
                        switch state {
                        case .tooHigh(max: let fiatValue),
                             .tooLow(min: let fiatValue):
                            return self.priceService
                                .moneyValuePair(
                                    fiatValue: fiatValue,
                                    cryptoCurrency: currency,
                                    usesFiatAsBase: activeInput == .fiat
                                )
                                .asSingle()
                                .map { pair -> AmountInteractorState in
                                    switch state {
                                    case .tooHigh:
                                        return .maxLimitExceeded(pair.base)
                                    case .tooLow:
                                        return .underMinLimit(pair.base)
                                    case .empty:
                                        return .empty
                                    case .inBounds:
                                        return .inBounds
                                    }
                                }
                        case .empty:
                            return .just(.empty)
                        case .inBounds:
                            return .just(.inBounds)
                        }
                    }
                    .asObservable()
            }
            .do(onError: { [effectRelay] error in
                if case .none = effectRelay.value {
                    effectRelay.accept(.failure(error))
                }
            })
            .catchError { error -> Observable<AmountInteractorState> in
                .just(
                    AmountInteractorState.error(
                        message: String(describing: error)
                    )
                )
            }
            .bindAndCatch(to: amountTranslationInteractor.stateRelay)
            .disposed(by: disposeBag)

        suggestedAmountsService.calculationState
            .compactMap(\.value)
            .bindAndCatch(to: suggestedAmountsRelay)
            .disposed(by: disposeBag)

        pairsService.fetch()
            .map { .value($0) }
            .catchErrorJustReturn(.invalid(.valueCouldNotBeCalculated))
            .startWith(.invalid(.empty))
            .bindAndCatch(to: pairsCalculationStateRelay)
            .disposed(by: disposeBag)

        let pairs = pairsCalculationState
            .compactMap(\.value)

        let pairForCryptoCurrency = Observable
            .combineLatest(
                pairs,
                cryptoCurrencySelectionService.selectedData
            )
            .map { pairs, item -> SupportedPairs.Pair? in
                pairs.pairs(per: item.cryptoCurrency).first
            }

        Observable
            .combineLatest(
                preferredPaymentMethodType.compactMap { $0 },
                amountTranslationInteractor.fiatAmount.compactMap(\.fiatValue),
                amountTranslationInteractor.cryptoAmount.compactMap(\.cryptoValue),
                pairForCryptoCurrency,
                fiatCurrencyService.displayCurrencyPublisher.asObservable()
            )
            .map { preferredPaymentMethod, fiat, crypto, pair, currency -> State in
                /// There must be a pair to compare to before calculation begins
                guard let pair = pair else {
                    return .empty(currency: currency)
                }

                let minFiatValue = pair.minFiatValue
                let maxFiatValue: FiatValue
                let paymentMethodId: String?
                let hardCodedMinimum = (FiatValue.create(major: "10.00", currency: currency) ?? minFiatValue)
                let maxMinFiatValue: FiatValue = try .max(hardCodedMinimum, minFiatValue)

                switch preferredPaymentMethod {
                case .card(let cardData):
                    maxFiatValue = cardData.topLimit
                    paymentMethodId = cardData.identifier
                case .account(let data):
                    maxFiatValue = data.topLimit
                    paymentMethodId = nil
                case .suggested(let method):
                    guard method.max.currency == pair.maxFiatValue.currency else {
                        return .empty(currency: currency)
                    }
                    maxFiatValue = try .min(pair.maxFiatValue, method.max)
                    paymentMethodId = nil
                case .linkedBank(let data):
                    maxFiatValue = data.topLimit
                    paymentMethodId = data.identifier
                }

                guard fiat.currencyType == maxMinFiatValue.currencyType,
                      fiat.currencyType == maxFiatValue.currencyType
                else {
                    return .empty(currency: currency)
                }

                if fiat.isZero {
                    return .empty(currency: currency)
                } else if try fiat > maxFiatValue {
                    return .tooHigh(max: maxFiatValue)
                } else if try fiat < maxMinFiatValue {
                    return .tooLow(min: maxMinFiatValue)
                }
                let data: CandidateOrderDetails = .buy(
                    paymentMethod: preferredPaymentMethod,
                    fiatValue: fiat,
                    cryptoValue: crypto,
                    paymentMethodId: paymentMethodId
                )

                return .inBounds(data: data, upperLimit: pair.maxFiatValue)
            }
            // Handle possible errors: it is unlikely to get here unless
            // there was a connection / BE error
            .catchError { _ in
                fiatCurrencyService.displayCurrencyPublisher
                    .asObservable()
                    .take(1)
                    .map { .empty(currency: $0) }
            }
            .bindAndCatch(to: stateRelay)
            .disposed(by: disposeBag)

        suggestedAmountsService.refresh()
    }

    // MARK: - Actions

    func createOrder(from candidate: CandidateOrderDetails) -> Single<CheckoutData> {
        orderCreationService.create(using: candidate)
    }
}

extension SelectionItemViewModel {

    var cryptoCurrency: CryptoCurrency {
        CryptoCurrency(code: id)!
    }
}

extension AmountInteractorEffect {
    var toBuyCryptoInteractorEffect: BuyCryptoScreenInteractor.Effect {
        switch self {
        case .failure(let error):
            return .failure(error)
        case .none:
            return .none
        }
    }
}
