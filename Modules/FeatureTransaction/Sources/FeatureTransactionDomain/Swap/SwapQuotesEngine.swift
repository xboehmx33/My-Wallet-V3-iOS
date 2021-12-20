// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import DIKit
import MoneyKit
import PlatformKit
import RxSwift

struct PricedQuote {
    let price: BigInt
    let networkFee: MoneyValue
    let staticFee: MoneyValue
    let sampleDepositAddress: String
}

final class SwapQuotesEngine {

    // MARK: - Private Properties

    private let stopSubject = PublishSubject<Void>()
    private let repository: OrderQuoteRepositoryAPI
    private let amount = BehaviorSubject<BigInt>(value: .zero)
    private var amountObservable: Observable<BigInt> {
        amount.asObservable()
    }

    // MARK: - Init

    init(repository: OrderQuoteRepositoryAPI = resolve()) {
        self.repository = repository
    }

    // MARK: - Public Functions

    func stop() {
        stopSubject.on(.next(()))
    }

    func updateAmount(_ amount: BigInt) {
        self.amount.onNext(amount)
    }

    func getRate(direction: OrderDirection, pair: OrderPair) -> Observable<PricedQuote> {
        Observable.combineLatest(
            quote(direction: direction, pair: pair),
            amountObservable
        )
        .map { (quote: OrderQuotePayload, amount: BigInt) in
            let interpolator = PricesInterpolator(prices: quote.quote.priceTiers)
            return PricedQuote(
                price: interpolator.rate(amount: amount),
                networkFee: quote.networkFee,
                staticFee: quote.staticFee,
                sampleDepositAddress: quote.sampleDepositAddress
            )
        }
        .share(replay: 1, scope: .whileConnected)
    }

    // MARK: - Private Functions

    private func quote(direction: OrderDirection, pair: OrderPair) -> Observable<OrderQuotePayload> {
        fetchQuote(direction: direction, pair: pair)
            .asObservable()
            .flatMap(weak: self) { (self, quote) -> Observable<OrderQuotePayload> in
                let delay = Int(quote.expiresAt.timeIntervalSince(quote.createdAt))
                return Observable.timer(
                    .seconds(delay),
                    period: .seconds(delay),
                    scheduler: ConcurrentDispatchQueueScheduler(qos: .background)
                )
                .flatMap(weak: self) { (self, _: Int) -> Observable<OrderQuotePayload> in
                    self.fetchQuote(direction: direction, pair: pair).asObservable()
                }
                .startWith(quote)
            }
            .take(until: stopSubject)
    }

    private func fetchQuote(direction: OrderDirection, pair: OrderPair) -> Single<OrderQuotePayload> {
        repository
            .fetchQuote(
                direction: direction,
                sourceCurrencyType: pair.sourceCurrencyType,
                destinationCurrencyType: pair.destinationCurrencyType
            )
            .asObservable()
            .asSingle()
    }
}
