// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import RxRelay
import RxSwift
import ToolKit

public protocol HistoricalFiatPriceServiceAPI {

    /// An observable that streams the calculation state of the service.
    var calculationState: Observable<ValueCalculationState<HistoricalFiatPriceResponse>> { get }

    /// A trigger that forces the service to fetch the updated price. Handy to call on currency type and value changes.
    var fetchTriggerRelay: PublishRelay<PriceWindow> { get }
}

public final class HistoricalFiatPriceService: HistoricalFiatPriceServiceAPI {

    // MARK: - Public Types

    public typealias CalculationState = ValueCalculationState<HistoricalFiatPriceResponse>

    // MARK: - HistoricalFiatPriceServiceAPI

    public var calculationState: Observable<CalculationState> {
        _ = setup
        return calculationStateRelay.asObservable()
    }

    public let fetchTriggerRelay = PublishRelay<PriceWindow>()

    // MARK: - Private Properties

    /// The associated crypto currency.
    private let cryptoCurrency: CryptoCurrency

    private let pairExchangeService: PairExchangeServiceAPI

    private let priceService: PriceServiceAPI

    private let fiatCurrencyService: FiatCurrencyServiceAPI

    private let scheduler: SchedulerType

    private let calculationStateRelay = BehaviorRelay<CalculationState>(value: .calculating)

    private let disposeBag = DisposeBag()

    private lazy var setup: Void = {
        let historicalPricesInWindow = Observable
            .combineLatest(
                fiatCurrencyService.displayCurrencyPublisher.asObservable(),
                fetchTriggerRelay.startWith(.day(.oneHour))
            )
            .throttle(.milliseconds(100), scheduler: scheduler)
            .flatMapLatest { [priceService, cryptoCurrency] fiatCurrency, window
                -> Observable<(HistoricalPriceSeries, PriceWindow)> in
                let prices = priceService
                    .priceSeries(of: cryptoCurrency, in: fiatCurrency, within: window)
                    .asObservable()
                return Observable.zip(prices, Observable.just(window))
            }
            .subscribe(on: scheduler)
            .observe(on: scheduler)

        Observable
            .combineLatest(pairExchangeService.fiatPrice(at: .now), historicalPricesInWindow)
            .map { payload in
                let (fiatValue, (prices, window)) = payload
                return HistoricalFiatPriceResponse(fiatValue: fiatValue, prices: prices, priceWindow: window)
            }
            .map(CalculationState.value)
            .startWith(.calculating)
            .catchAndReturn(.calculating)
            .bindAndCatch(to: calculationStateRelay)
            .disposed(by: disposeBag)
    }()

    // MARK: - Setup

    /// Creates a historical fiat price service.
    ///
    /// - Parameters:
    ///   - cryptoCurrency:      A crypto currency.
    ///   - pairExchangeService: A pair exchange service.
    ///   - priceService:        A price service.
    ///   - fiatCurrencyService: A fiat currency service.
    ///   - scheduler:           A scheduler.
    public init(
        cryptoCurrency: CryptoCurrency,
        pairExchangeService: PairExchangeServiceAPI,
        priceService: PriceServiceAPI = resolve(),
        fiatCurrencyService: FiatCurrencyServiceAPI,
        scheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .background)
    ) {
        self.cryptoCurrency = cryptoCurrency
        self.pairExchangeService = pairExchangeService
        self.priceService = priceService
        self.fiatCurrencyService = fiatCurrencyService
        self.scheduler = scheduler
    }
}
